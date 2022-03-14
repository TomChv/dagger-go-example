package greeting

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestHelloDagger(t *testing.T) {
	res := HelloDagger()
	assert.Equal(t, "Hello dagger!", res)
}
