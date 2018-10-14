"""
    MLP(h::Int...;kwargs...)


Creates a multi layer perceptron according to given hidden states.
First hidden state is equal to input size and the last one equal to output size.

    (m::MLP)(x;prob=0)


Runs MLP with given input `x`. `prob` is the dropout probability.

# Keywords

* `winit=xavier`: weight initialization distribution
* `bias=zeros`: bias initialization distribution
* `f=ReLU()`: activation function
* `atype=KnetLayers.arrtype` : array type for parameters.
   Default value is KnetArray{Float32} if you have gpu device. Otherwise it is Array{Float32}


"""
struct MLP <: Layer
     layers::Tuple{Vararg{Linear}}
     f
end
function MLP(h::Int...; winit=xavier, binit=zeros, f=ReLU(), atype=arrtype)
    singlelayer(input,ouput) = Linear(input=input, output=ouput, winit=winit, binit=binit, atype=atype)
    MLP(singlelayer.(h[1:end-1], h[2:end]),f)
end
function (m::MLP)(x;prob=0)
    for layer in m.layers
        x = layer(dropout(x,prob))
        if layer !== m.layers[end]
            x = m.f(x)
        end
    end
    return x
end
