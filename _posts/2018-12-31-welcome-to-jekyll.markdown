---
layout: post
title:  "Low-rank Matrices and Inpainting"
date:   2018-12-31 01:11:52 -0500
categories: jekyll update
---
{% include mathMode.html %}
Before we begin with the mathematics we should first start with defining the
problem and the terms associated with it. Image [inpainting](https://en.wikipedia.org/wiki/Inpainting "Wikipedia - Inpainting") is the reconstruction of a corrupted or *damaged* image through some
means. In this post I will be discussing an interesting method that can be used
to reconstruct an image based on a signal processing technique known as [compressed sensing](https://en.wikipedia.org/wiki/Compressed_sensing "Wikipedia - Compressed sensing") which
 can yield decent results.

# Low-rank Matrix Completion
Before we can reconstruct the damaged image we start by considering the image in
a simpler form: as a matrix of pixel values. From this we see that
reconstructing an image can be viewed as the reconstruction of a generic matrix.
Unfortunately, as you may have guessed it is generally impossible to
reconstruct a generic matrix given nothing except that it has been corrupted in
several places. However, we can still reconstruct some matrices given certain
assumptions about the matrices.

The particular assumption we consider is that of
low-rank. This actually is a pretty decent assumption to make in a lot of modern
settings. For example, many social networks can be represented by sparse low-rank
matrices. In addition, the famous [Netflix Problem](https://en.wikipedia.org/wiki/Netflix_Prize "Wikipedia - Netflix Prize") involves a matrix of Netflix users against their movie ratings which
forms an inherently sparse low-rank matrix (since most people have not watched
and rated every show on Netflix). This new problem we have formed can be written
more formally as:

$\underset{X}{\min} \text{   } rank(X) \text{ ,  s.t.  } X_{ij} = M_{ij} \text{, } \forall (i,j) \in \Omega$

Where $X$ is the matrix that we are trying to reconstruct, $M$ is target Matrix we
are trying to reconstruct to, and $\Omega$ is the set of indices in the
given $X$ matrix that we known are uncontaminated/undamaged.

Reconstructing a matrix under this assumption that the matrix is of low-rank is
actually possible; however, it is computationally intractable and thus isn't
particularly useful in most settings that we would like to use it for. If you
want to fix your image you don't want to wait 5 hours for it to reconstruct, you
want it fixed quickly. To solve this issue we can slightly modify our equation to
instead minimize the nuclear norm of the matrix.

The Nuclear Norm of a matrix is the sum of the absolute values of its singular values and is represented by
$||\cdot||\_\*$. You can also think of this norm as applying the $\ell^1$ norm to the
singular values of $X$. Through a series of mathematical arguments it has been
shown that this nuclear norm is a good approximation for the rank of a matrix.
This is fortunate because there do exist computationally tractable methods for
solving this new problem which we formally define as follows.

$\underset{X}{\min} \text{   } \|\|X\|\|\_\* \text{ ,  s.t.  } X_{ij} = M_{ij} \text{, } \forall (i,j) \in \Omega$

At this point we have finally arrived at the problem of tractable low-rank
matrix completion. This particular problem can now be solved using a couple of
different efficient optimization methods including the [ADMM](http://stanford.edu/~boyd/admm.html "Stanford - ADMM") method which is a subset of the [Augmented Lagrangian Methods](https://en.wikipedia.org/wiki/Augmented_Lagrangian_method "Wikipedia - Augmented Lagrangian").   

# Image Inpainting
So we starting discussing an image and ending up discussing low-rank matrices but
how exactly does this information help us? As you may have thought, images are inherently neither
sparse nor low-rank; however, we can apply a signal transform to make a given image
sparse.

An example transformation we may apply to the image is the fourier transform (or
in our case [discrete fourier transform](https://en.wikipedia.org/wiki/Discrete_Fourier_transform "Wikipedia - Discrete fourier transform"))
which decomposes a given function (the image in our case) into its constituent
frequencies (sines and cosines) that make it up. If you're having difficulty
visualizing how an image can be a function that can be broken up into different
frequencies first consider a grayscale image and then think of it as a surface embedded in $\mathbb R^3$ with x,y values being the x,y pixel coordinates in the image and the z value being the numerical
brightness value associated with that pixel (similar to a heatmap).     






You’ll find this post in your `_posts` directory. Go ahead and edit it and re-build the site to see your changes. You can rebuild the site in many different ways, but the most common way is to run `jekyll serve`, which launches a web server and auto-regenerates your site when a file is updated.

To add new posts, simply add a file in the `_posts` directory that follows the convention `YYYY-MM-DD-name-of-post.ext` and includes the necessary front matter. Take a look at the source for this post to get an idea about how it works.

Jekyll also offers powerful support for code snippets:

{% highlight ruby %}
def print_hi(name)
  puts "Hi, #{name}"
end
print_hi('Tom')
#=> prints 'Hi, Tom' to STDOUT.
{% endhighlight %}

Check out the [Jekyll docs][jekyll-docs] for more info on how to get the most out of Jekyll. File all bugs/feature requests at [Jekyll’s GitHub repo][jekyll-gh]. If you have questions, you can ask them on [Jekyll Talk][jekyll-talk].

[jekyll-docs]: https://jekyllrb.com/docs/home
[jekyll-gh]:   https://github.com/jekyll/jekyll
[jekyll-talk]: https://talk.jekyllrb.com/
