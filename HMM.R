##########################
# Fit Hidden Markov Model
##########################

library('RcppHMM')
set.seed(0) # Set seed for reproducibility


### Set parameters.

n_reps = 1                              # Number of initializations.
n_obs = 150
n_subj = 112
state_names = c('S1','S2','S3','S4')
vars =  c(1,3,5,7)                      # PLI: c(1,3,5,7), Modularity: c(2,4,6,8)
 

# Load data.
obs = as.matrix(read.csv('C:\\Users\\Jonah Kember\\Documents\\CRISS Grant\\states.csv'))
obs = t(obs)
obs = as.matrix(obs[vars,])

n_dim = dim(obs)[1]
n_states = length(state_names)


# Normalize.
for (i in 1:n_dim) {
  obs[i,] = (obs[i,] - mean(obs[i,])) / sd(obs[i,])
}


# Prep observations.
all_seq = array(0,dim = c(n_dim,n_obs,n_subj))
all_seq[,,1] = obs[,c(1:n_obs)]
for(i in 1:(n_subj - 1)){
  all_seq[,,(i + 1)] = obs[,((i*n_obs):((i*n_obs) + (n_obs - 1)))]
}


### Estimate parameters.

hmm_all = list()
fits = matrix(0,n_reps)
for (reps in 1:n_reps) {
  cat('\nRepetition',reps,'\n')
  hmm = initGHMM(n_states, n_dim)
  hmm$StateNames = state_names
  
  hmm = learnEM(hmm, all_seq, iter = 150, delta = .005, pseudo = 0)
  verifyModel(hmm)
  
  fits[reps] = loglikelihood(hmm,all_seq)
  hmm_all[[reps]] = hmm
}

optimal_model = which.max(fits)
hmm = hmm_all[[optimal_model]]

plot(fits)

# Estimate sequence of states visited.

state_seqs = list(dim = c(n_subj,150))
for (subj in 1:n_subj){
  state_seqs[subj] = list(viterbi(hmm, all_seq[,,subj]))
}

# Calculate dwell times.

dwell_times = matrix(0,n_subj,n_states)
for (su in 1:n_subj) { 
  for (st in 1:n_states) {
    dwell_times[su,st] = sum(factor(state_seqs[[su]]) == state_names[st])/n_obs
  }
}

plot(dwell_times[,1], lwd = 2)
plot(dwell_times[,2], col = 'orange', lwd = 2)
plot(dwell_times[,3], col = 'blue', lwd = 2)
  
# Write to csv.

write.csv(state_seqs,"C:\\Users\\Jonah Kember\\Documents\\Downloads\\state_seqs.csv")
write.csv(dwell_times,"C:\\Users\\Jonah Kember\\Documents\\Downloads\\dwell_times.csv")
