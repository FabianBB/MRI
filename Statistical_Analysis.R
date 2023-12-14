# Computational Research Skills Assignment (Statistical Analysis)
# Authors: Barbora Rakovanová (i6243774), Fabian Brock (i6248959), 
# Chalisa Mendini (i6241400), Valentin Michaux (i6236951)
# 15.12.2023


library(dplyr)
library(graphics)
library(MASS)
library(ggplot2)
library(scales)
library(gridExtra)

#loading the data
scan_records <- read.csv("ScanRecords.csv",
                 header = TRUE,
                 sep = ",",
                 dec = ".")

summary(scan_records)


#plotting duration of full data
ggplot(scan_records, aes(x = 1:618, y = Duration)) +
  geom_line() +
  labs(title = "MRI Scan Durations",
       x = "Observation",
       y = "Duration (in fraction of hours)")

sum(scan_records$PatientType %in% "Type 1") #379 type 1 patients
sum(scan_records$PatientType %in% "Type 2") #239 type 2 patients

#splitting the full dataset into two separate datasets of Type 1 and Type 2 patients
scan_records_type1 <- scan_records[scan_records$PatientType == "Type 1", ]
scan_records_type2 <- scan_records[scan_records$PatientType == "Type 2", ]

dates <- unique(scan_records$Date)

appointment_count_t1 <- rep(NA, times = length(dates))
appointment_count_t2 <- rep(NA, times = length(dates))

for(d in 1:length(dates)){
  appointment_count_t1[d] <- sum(scan_records_type1$Date %in% dates[d])
  appointment_count_t2[d] <- sum(scan_records_type2$Date %in% dates[d])
}

#type 1 patients appointments per day:
min(appointment_count_t1)#10
max(appointment_count_t1)#23
mean(appointment_count_t1)#16.47826

#type 2 patients appointments per day:
min(appointment_count_t2)#9
max(appointment_count_t2)#13
mean(appointment_count_t2)#10.3913

#plotting type 1 and type 2 patient durations
type1_plot <- ggplot(scan_records_type1, aes(x = 1:379, y = Duration)) +
  geom_line() +
  labs(title = "MRI Scan Durations of Type 1 Patients",
       x = "Observation",
       y = "Duration (in fraction of hours)")


type2_plot <- ggplot(scan_records_type2, aes(x = 1:239, y = Duration)) +
  geom_line() +
  labs(title = "MRI Scan Durations of Type 2 Patients",
       x = "Observation",
       y = "Duration (in fraction of hours)")

grid.arrange(type1_plot, type2_plot, ncol = 2)

#duration means and standard deviations:
t1_mean <- mean(scan_records_type1$Duration)#0.4326608 -> 26min
t2_mean <- mean(scan_records_type2$Duration)#0.6693389 -> 40min
t1_sd <- sd(scan_records_type1$Duration)#0.09777424 -> cca 6min
t2_sd <- sd(scan_records_type2$Duration)#0.1872859 -> cca 11min

#t1 duration histogram
graphics::hist(scan_records_type1$Duration, col = "lightblue", border = "black",
               probability = TRUE, xlab = "Duration (in fractions of hours)",
               main = "Histogram of Type 1 MRI Durations")


#t2 duration histogram
graphics::hist(scan_records_type2$Duration, col = "lightblue", border = "black",
               probability = TRUE, xlab = "Duration (in fractions of hours)",
               main = "Histogram of Type 2 Patient MRI Durations")




##################  BOOTSTRAP TYPE 1 PATIENTS ############################

# --------- mean and sd duration -------------#

n1 <- length(scan_records_type1$Duration)
B1 <- 499
alpha <- 0.05

Q.star <- rep(NA, times = B1)
X.bar <- mean(scan_records_type1$Duration)
St.Dev <- sd(scan_records_type1$Duration)
X.star.bar <- rep(NA, times = B1)
X.star.sd <- rep(NA, times = B1)

# performing bootstrap
for(b in 1:B1){
  J1 <- sample.int(n1 , size = n1 , replace = TRUE)
  X.star <- scan_records_type1$Duration[J1]
  X.star.bar[b] <- mean(X.star)
  X.star.sd[b] <- sd(X.star)
  Q.star[b] <- sqrt(n1) * (X.star.bar[b] - X.bar) / X.star.sd[b]
}

#main bootstrap results
t1_avg_duration <- mean(X.star.bar) #0.4323432
t1_sd_duration <- mean(X.star.sd) #0.09786042

#critical values:
cv_lower1 <- quantile(Q.star, probs = alpha/2)
cv_upper1 <- quantile(Q.star, probs = 1-alpha/2)

#confidence interval:
CI_dur_t1_lower <- X.bar - cv_upper1*St.Dev/sqrt(n1)
CI_dur_t1_upper <- X.bar - cv_lower1*St.Dev/sqrt(n1)


#histogram of T1 durations with fitted distribution:
hist_dur_t1 <- ggplot(scan_records_type1, aes(x = Duration)) +
  geom_histogram(bins = 15, fill = "lightblue", color = "black", alpha = 0.7, aes(y = ..density..)) +
  stat_function(fun = function(x) dnorm(x, mean = t1_avg_duration, sd = t1_sd_duration), color = "darkred", size = 1) +
  labs(title = "Histogram of Type 1 Patient MRI Durations 
       with Fitted Normal Distribution",
       x = "Duration (in fractions of hours)",
       y = "Density") +
  theme_minimal()

hist_dur_t1

#calculating percentiles:
t1_duration_percentiles <- quantile(X.star.bar, c(0.3, 0.4, 0.5, 0.6, 0.75))
print(t1_duration_percentiles)



# ----------- mean arrival time / arrival rate ------------- #
# opening hours: 8:00 - 17:00

#dataset containing times between T2 patient arrivals
X.inter_arrival <- rep(NA, times = n1 - 1) 

for(i in 1: (n1-1)){
  if(scan_records_type1$Date[i] == scan_records_type1$Date[i+1]){
    X.inter_arrival[i] <- scan_records_type1$Time[i+1] - scan_records_type1$Time[i]
  } else {
    X.inter_arrival[i] <- (17 - scan_records_type1$Time[i]) + (scan_records_type1$Time[i+1] - 8)
  }
}

print(X.inter_arrival)
mean(X.inter_arrival)#0.5453439


X.bar2 <- mean(X.inter_arrival) #0.5453439
St.Dev2 <- sd(X.inter_arrival)#0.5833021
X.star.bar2 <- rep(NA, times = B1)
X.star.sd2 <- rep(NA, times = B1)
Q.star2 <- rep(NA, times = B1)

#performing bootstrap
for (b in 1 : B1) {
  J2 <- sample.int(n1-1 , size = (n1-1) , replace = TRUE)
  X.star2 <- X.inter_arrival[J2]
  X.star.bar2[b] <- mean(X.star2)
  X.star.sd2[b] <- sd(X.star2)
  Q.star2[b] <- sqrt(n1-1)*(X.star.bar2[b] - X.bar2) / X.star.sd2[b]
}

#main bootstrap result
t1_avg_inter_arrival <- mean(X.star.bar2) #0.5463435
#mean = 1/rate -> rate = 1.83035

#critical values:
cv_lower2 <- quantile(Q.star2, probs = alpha/2)
cv_upper2 <- quantile(Q.star2, probs = 1-alpha/2)

#confidence interval:
CI_arrival_t1_lower <- X.bar2 - cv_upper2*St.Dev2/sqrt(n1-1)#0.4906503
CI_arrival_t1_upper <- X.bar2 - cv_lower2*St.Dev2/sqrt(n1-1)#0.6089241

#histogram of T1 inter-arrival times with fitted distribution
hist_arrival_t1 <- ggplot(data.frame(X.inter_arrival), aes(x = X.inter_arrival)) +
  geom_histogram(bins = 12, fill = "lightblue", color = "black", alpha = 0.7, aes(y = ..density..)) +
  stat_function(fun = function(x) dexp(x, rate = 1/t1_avg_inter_arrival), color = "darkred", linewidth = 1) +
  labs(title = "Histogram of Type 1 Patient Inter-Arrival Times 
       with Fitted Exponential Distribution",
       x = "Inter-Arrival Time",
       y = "Density") +
  theme_minimal() +
  coord_cartesian(ylim = c(0, 1.2))

hist_arrival_t1

grid.arrange(hist_dur_t1, hist_arrival_t1, ncol = 2)



################## BOOTSTRAP TYPE 2 PATIENTS ###########################

# --------------- duration ------------#

nr.sim <- 1000
n2 <- length(scan_records_type2$Duration)
X.bar3 <- mean(scan_records_type2$Duration)
St.Dev3 <- sd(scan_records_type2$Duration)
X.star.bar3 <- rep(NA, times = B1)
X.star.sd3 <- rep(NA, times = B1)
X.star.gamma.shape <- rep(NA, times = B1)
X.star.gamma.rate <- rep(NA, times = B1)

CI_lower1 <- rep(NA, times = nr.sim)
CI_upper1 <- rep(NA, times = nr.sim)
reject1 <- rep(0, times = nr.sim)

#Monce Carlo simulation
for(m in 1:nr.sim){
  indices <- sample.int(n2, size = n2, replace = TRUE)
  sim.sample <- scan_records_type2$Duration[indices]
  sim.sample.mean <- mean(sim.sample)
  Q <- sqrt(n2)*(sim.sample.mean - X.bar3)/sd(sim.sample)
  Q.star3 <- rep(NA, times = B1)
  
  #bootstrap procedure
  for (b in 1:B1) {
    J3 <- sample.int(n2, size = n2, replace = TRUE)
    X.star3 <- sim.sample[J3]
    X.star.bar3[b] <- mean(X.star3)
    X.star.sd3[b] <- sd(X.star3)
    fit.gamma.star <- fitdistr(X.star3, densfun = "gamma")
    X.star.gamma.shape[b] <- fit.gamma.star$estimate[1]
    X.star.gamma.rate[b] <- fit.gamma.star$estimate[2]
    Q.star3[b] <- sqrt(n2)*(X.star.bar3[b] - sim.sample.mean) / X.star.sd3[b]
  }
  cv.star_lower1 <- quantile(Q.star3, probs = alpha/2)
  cv.star_upper1 <- quantile(Q.star3, probs = 1-alpha/2)

  CI_lower1[m] <- sim.sample.mean - cv.star_upper1*St.Dev3/sqrt(n2)
  CI_upper1[m] <- sim.sample.mean - cv.star_lower1*St.Dev3/sqrt(n2)

  if(X.bar3 < CI_lower1[m] || X.bar3 > CI_upper1[m]){
    reject1[m] <- 1
  }
}

ERF1 <- mean(reject1)
print(paste("Rejection occurred in ", 100 * ERF1, "% of the cases."))

#main bootstrap results:
t2_avg_duration <- mean(X.star.bar3) #0.6697284
t2_sd_duration <- mean(X.star.sd3) #0.1870765

t2_avg_gamma_shape <- mean(X.star.gamma.shape) #12.67705
t2_avg_gamma_rate <- mean(X.star.gamma.rate) #18.92794


#critical values:
cv_lower3 <- quantile(Q.star3, probs = alpha/2)
cv_upper3 <- quantile(Q.star3, probs = 1-alpha/2)

#confidence interval:
CI_dur_t2_lower <- X.bar3 - cv_upper3*St.Dev3/sqrt(n2)#0.6429449
CI_dur_t2_upper <- X.bar3 - cv_lower3*St.Dev3/sqrt(n2)#0.6985946


#histogram of T2 durations with fitted gamma distribution:
hist_dur_t2 <- ggplot(scan_records_type2, aes(x = Duration)) +
  geom_histogram(bins = 11, fill = "lightblue", color = "black", alpha = 0.7, aes(y = ..density..)) +
  stat_function(fun = function(x) dgamma(x, shape = t2_avg_gamma_shape, rate = t2_avg_gamma_rate), color = "darkred", size = 1) +
  labs(title = "Histogram of Type 2 Patient MRI Durations 
       with Fitted Gamma Distribution",
       x = "Duration (in fractions of hours)",
       y = "Density") +
  theme_minimal()

hist_dur_t2


#calculating percentiles
t2_duration_percentiles <- quantile(X.star.bar3, c(0.3, 0.4, 0.5, 0.6, 0.75))
print(t2_duration_percentiles)



# ----------- inter-arrival time / arrival rate -------------#

X.inter_arrival2 <- rep(NA, times = n2 - 1) #sample size: n2-1

#calculating inter-arrival times of T2 patients
for(i in 1: (n2-1)){
  if(scan_records_type2$Date[i] == scan_records_type2$Date[i+1]){
    X.inter_arrival2[i] <- scan_records_type2$Time[i+1] - scan_records_type2$Time[i]
  } else {
    X.inter_arrival2[i] <- (17 - scan_records_type2$Time[i]) + (scan_records_type2$Time[i+1] - 8)
  }
}

mean(X.inter_arrival2) #0.8666387

t2_arrival_mean <- mean(X.inter_arrival2)
t2_arrival_sd <- sd(X.inter_arrival2)


X.bar4 <- mean(X.inter_arrival2) #0.8666387
St.Dev4 <- sd(X.inter_arrival2)
X.star.bar4 <- rep(NA, times = B1)
X.star.bar4 <- rep(NA, times = B1)
X.star.sd4 <- rep(NA, times = B1)
Q.star4 <- rep(NA, times = B1)

CI_lower2 <- rep(NA, times = nr.sim)
CI_upper2 <- rep(NA, times = nr.sim)
reject2 <- rep(0, times = nr.sim)

#Monte Carlo simulation
for(c in 1:nr.sim){
  indices2 <- sample.int(n2-1, size = n2-1, replace = TRUE)
  sim.sample2 <- X.inter_arrival2[indices2]
  sim.sample.mean2 <- mean(sim.sample2)
  Q <- sqrt(n2-1)*(sim.sample.mean2 - X.bar4)/sd(sim.sample2)
  Q.star4 <- rep(NA, times = B1)
  
  #bootstrap procedure
  for (b in 1 : B1) {
    J4 <- sample.int(n2-1 , size = (n2-1) , replace = TRUE)
    X.star4 <- sim.sample2[J4]
    X.star.bar4[b] <- mean(X.star4)
    X.star.sd4[b] <- sd(X.star4)
    Q.star4[b] <- sqrt(n2-1)*(X.star.bar4[b] - sim.sample.mean2) / X.star.sd4[b]
  }
  
  cv.star_lower2 <- quantile(Q.star4, probs = alpha/2)
  cv.star_upper2 <- quantile(Q.star4, probs = 1-alpha/2)
  
  CI_lower2[c] <- sim.sample.mean2 - cv.star_upper2*St.Dev4/sqrt(n2-1)
  CI_upper2[c] <- sim.sample.mean2 - cv.star_lower2*St.Dev4/sqrt(n2-1)
  
  if(X.bar4 < CI_lower2[c] || X.bar4 > CI_upper2[c]){
    reject2[c] <- 1
  }
}

ERF2 <- mean(reject2)
print(paste("Rejection occurred in ", 100 * ERF2, "% of the cases."))

#main bootstrap results:
t2_avg_inter_arrival <- mean(X.star.bar4) #0.8674233 
t2_sd_inter_arrival <- mean(X.star.sd4) #0.3102543

#critical values:
cv_lower4 <- quantile(Q.star4, probs = alpha/2)
cv_upper4 <- quantile(Q.star4, probs = 1-alpha/2)

#confidence interval:
CI_arrival_t2_lower <- X.bar4 - cv_upper4*St.Dev4/sqrt(n2-1)#0.823297
CI_arrival_t2_upper <- X.bar4 - cv_lower4*St.Dev4/sqrt(n2-1)#0.9071094


#histogram of T2 inter-arrival times with fitted distribution
hist_arrival_t2 <- ggplot(data.frame(X.inter_arrival2), aes(x = X.inter_arrival2)) +
  geom_histogram(bins = 15, fill = "lightblue", color = "black", alpha = 0.7, aes(y = ..density..)) +
  stat_function(fun = function(x) dnorm(x, mean = t2_avg_inter_arrival, sd = t2_sd_inter_arrival), color = "darkred", linewidth = 1) +
  labs(title = "Histogram of Type 2 Patient Inter-Arrival Times 
       with Fitted Normal Distribution",
       x = "Inter-Arrival Time",
       y = "Density") +
  theme_minimal()

hist_arrival_t2

grid.arrange(hist_dur_t2, hist_arrival_t2, ncol = 2)
