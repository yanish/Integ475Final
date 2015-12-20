---------------------------
Literature Review

ZOMBIE PLANNING !!
---------------------------

First we consulted the Web of Science, downloading all articles with the key word "zombie". We received over 700 results. From this we created a csv and graphml file to analyze some key players in this topic area.

One approach was looking at the networks of the articles. Those that cited each other may be talking about certain aspects of zombies or how to best navigate a zombie world.
We plotted a network with weights below 4 and degrees below 6.

```{r, echo=FALSE}
library(igraph)
library(dplyr)
library(ggplot2)

setwd("C:/Users/Mgnwylie/Documents/INTEGFinal/Integ475Final/Networks")

network <- read.graph("C:/Users/Mgnwylie/Documents/INTEGFinal/Integ475Final/Networks/net.graphml", format = "graphml")

dat <- read.csv("C:/Users/Mgnwylie/Documents/INTEGFinal/Integ475Final/Data/dat.csv")

plot(network)

network <- simplify(network, remove.multiple = TRUE, remove.loops = TRUE)
network <- delete.edges(network, which(E(network)$weight <4))
network <- delete.vertices(network, which(degree(network) <6))

summary(network)

plot(network, edge.arrow.size=4, vertex.label=NA)
```

These are the top 18 articles we found in the subject area.

```{r, echo=FALSE}
V(network)$info
```

The articles had two main subject areas: philosophy and crime in south Africa.

The philosophy texts are concerned with the state of mind and body (@book{armstrong2002materialist). Philosophers in these texts speak of "philosophical zombies" or people that exist who are physically identical to humans but lack qualia (or conciousness/a personal experience) (@article{block1993consciousness; @article{nagel1974like). Armstrong (1968) debates the philosophy of mind and the difference between the physical brain and the mind that lives inside it. Chalmers (1997) further developed Armstrong's idea in relation to zombies saying that you could perceive a whole world where people have brains but no consciousness (@book{chalmers1997conscious).
Ultimately Armstrong (1968), and Chalmers (1997) are bringing forward the difference between the physical and mental in arguments about zombies possible existence, concluding that zombies are physically possible. This leads to ethical arguments in how humans interact with zombies, assuming they come into existence.
However, Dennett (1993) argues the opposite. The argument is that if we are physically identical then we are all zombies to begin with (@article{block1993consciousness).
These arguments are about dualism and materialism of humans. We are dualistic in the way that we are a brain and conciousness, and materialistic in the way that our physical is our fundamental state (@book{papineau2002thinking)

The second network of articles focuses on claims of zombie court arguments in South Africa (@article{comaroff2004criminal). Ashforth (2005) speaks of people taken by witches and transformed into zombies (@book{ashforth2005witchcraft). How South Africa deals with these instances may provide some insight into how we should deal with issues of zombies as humans.
