library(ggplot2)

race_votes <- read.csv('dropout-votes.csv')
race_votes[is.na(race_votes$n_days_dropped_out),'n_days_dropped_out'] <- 0
race_votes[is.na(race_votes$n_days_clinched),'n_days_clinched'] <- 0

dropout_votes <- aggregate(x=race_votes[,c('n_votes', 'race_n_votes')], by=race_votes[,c('candidate_id', 'n_days_dropped_out')], FUN=sum)

dropout_votes$n_votes0 <- ave(dropout_votes$n_votes, dropout_votes$candidate_id, FUN=function(x) { x[1] })
dropout_votes$all_votes0 <- ave(dropout_votes$race_n_votes, dropout_votes$candidate_id, FUN=function(x) { x[1] })

dropout_votes$n_votes_cum <- ave(dropout_votes$n_votes, dropout_votes$candidate_id, FUN=cumsum)
dropout_votes$all_votes_cum <- ave(dropout_votes$race_n_votes, dropout_votes$candidate_id, FUN=cumsum)
dropout_votes$percent0 <- dropout_votes$n_votes0 / dropout_votes$all_votes0
dropout_votes$percent_cum <- ifelse(dropout_votes$n_days_dropped_out == 0, dropout_votes$percent0, (dropout_votes$n_votes_cum - dropout_votes$n_votes0) / (dropout_votes$all_votes_cum - dropout_votes$all_votes0))
dropout_votes$percent_normalized <- dropout_votes$percent_cum / dropout_votes$percent0

# Filter out minor candidates
dropout_votes <- dropout_votes[dropout_votes$n_votes0 > 500000,]

# Filter out people who didn't drop out
dropout_votes$max_n_days_dropped_out <- ave(dropout_votes$n_days_dropped_out, dropout_votes$candidate_id, FUN=max)
dropout_votes <- dropout_votes[dropout_votes$max_n_days_dropped_out > 0,]

clinch_votes <- aggregate(x=race_votes[,c('n_votes', 'race_n_votes')], by=race_votes[,c('candidate_id', 'n_days_clinched')], FUN=sum)
clinch_votes$n_votes0 <- ave(clinch_votes$n_votes, clinch_votes$candidate_id, FUN=function(x) { x[1] })
clinch_votes$all_votes0 <- ave(clinch_votes$race_n_votes, clinch_votes$candidate_id, FUN=function(x) { x[1] })
clinch_votes$n_votes_cum <- ave(clinch_votes$n_votes, clinch_votes$candidate_id, FUN=cumsum)
clinch_votes$all_votes_cum <- ave(clinch_votes$race_n_votes, clinch_votes$candidate_id, FUN=cumsum)
clinch_votes$percent0 <- clinch_votes$n_votes0 / clinch_votes$all_votes0
clinch_votes$percent_cum <- ifelse(clinch_votes$n_days_clinched == 0, clinch_votes$percent0, (clinch_votes$n_votes_cum - clinch_votes$n_votes0) / (clinch_votes$all_votes_cum - clinch_votes$all_votes0))
clinch_votes$percent_normalized <- clinch_votes$percent_cum / clinch_votes$percent0

# Filter out non-winners
clinch_votes$max_n_days_clinched <- ave(clinch_votes$n_days_clinched, clinch_votes$candidate_id, FUN=max)
clinch_votes <- clinch_votes[clinch_votes$max_n_days_clinched > 0,]

ggplot(clinch_votes, aes(x=n_days_clinched, y=100*percent_cum, color=candidate_id)) +
  expand_limits(x=200) +
  geom_line() +
  geom_label(
    data=clinch_votes[clinch_votes$n_days_clinched == clinch_votes$max_n_days_clinched & clinch_votes$candidate_id == '2016 Dem clinton',],
    aes(label=paste(
      candidate_id,
      ': ',
      round(100 * percent0, 1),
      '% before clinch → ',
      round(100 * percent_cum, 1),
      '% after',
      sep='')),
    position=position_dodge(1),
    hjust=-0.01
  ) +
  geom_label(
    data=clinch_votes[clinch_votes$n_days_clinched == clinch_votes$max_n_days_clinched & clinch_votes$candidate_id != '2016 Dem clinton',],
    aes(label=paste(
      candidate_id,
      ': ',
      round(100 * percent0, 1),
      '% → ',
      round(100 * percent_cum, 1),
      '%',
      sep='')),
    position=position_dodge(1),
    hjust=-0.01
  ) +
  ggtitle('Percent of vote after clinching nomination') +
  labs(x='Number of days since clinch', y='') +
  theme_bw() +
  theme(
    legend.position='none',
    rect=element_blank()
  )

#ggplot(dropout_votes[dropout_votes$n_days_dropped_out != 0,], aes(x=n_days_dropped_out, y=percent_normalized, color=candidate_id)) +
#  expand_limits(x=200) +
#  geom_line() +
#  geom_label(
#    data=dropout_votes[dropout_votes$n_days_dropped_out == dropout_votes$max_n_days_dropped_out & dropout_votes$candidate_id == '2016 GOP kasich',],
#    aes(label=paste(
#      candidate_id,
#      ': ',
#      round(100 * percent0, 1),
#      '% before dropping out → ',
#      round(100 * percent_cum, 1),
#      '% after',
#      sep='')),
#    position=position_dodge(1),
#    hjust=-0.01
#  ) +
#  geom_label(
#    data=dropout_votes[dropout_votes$n_days_dropped_out == dropout_votes$max_n_days_dropped_out & dropout_votes$candidate_id != '2016 GOP kasich',],
#    aes(label=paste(
#      candidate_id,
#      ': ',
#      round(100 * percent0, 1),
#      '% → ',
#      round(100 * percent_cum, 1),
#      '%',
#      sep='')),
#    position=position_dodge(1),
#    hjust=-0.01
#  ) +
#  ggtitle('How well a candidate did after dropping out, relative to before') +
#  labs(x='Number of days since dropping out', y='Percent of vote, divided by pre-dropout cumulative percentage') +
#  theme_bw() +
#  theme(
#    legend.position='none'
#  )
