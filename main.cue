package main

import (
	"dagger.io/dagger"
	"universe.dagger.io/go"
	"universe.dagger.io/bash"
	"universe.dagger.io/docker"
	"universe.dagger.io/alpine"
)

dagger.#Plan & {
	client: {
		filesystem: ".": read: {
			contents: dagger.#FS
			include: ["go.mod", "go.sum", "**/*.go"]
		}

		env: DOCKER_PASSWORD: dagger.#Secret
	}

	actions: {
		// Alias to code
		_code: client.filesystem.".".read.contents

		// Improved go base image with useful tool
		_base: go.#Image & {
			packages: {
				"build-base": version: _
				"bash": version:       _
			}
		}

		// Binary name
		_binaryName: "dagger-go-example"

		// Run go unit test
		"unit-test": go.#Test & {
			source:  _code
			package: "./..."
			input:   _base.output
		}

		// Build go project
		build: go.#Build & {
			source: _code
		}

		// Run integration test (depends on build)
		"integration-test": bash.#Run & {
			input: _base.output
			script: contents: """
					$BIN | grep "Hello dagger!"
				"""
			mounts: "binary": {
				contents: build.output
				dest:     "/usr/bin"
			}
			env: BIN: _binaryName
		}

		// Build docker image (depends on build)
		image: {
			_base: alpine.#Build & {}

			docker.#Build & {
				steps: [
					docker.#Copy & {
						input:    _base.output
						contents: build.output
						dest:     "/usr/bin"
					},
					docker.#Set & {
						config: cmd: [_binaryName]
					},
				]
			}
		}

    // Push image to remote registry (depends on image)
		push: {
			// Docker username
			_dockerUsername: "the0only0vasek"

			docker.#Push & {
				"image": image.output
				dest:    "\(_dockerUsername)/dagger-go-example"
				auth: {
					username: "\(_dockerUsername)"
					secret:   client.env.DOCKER_PASSWORD
				}
			}
		}
	}
}
