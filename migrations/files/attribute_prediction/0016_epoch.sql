-- epoch: weak entity owned by model_run (training log)
CREATE TABLE attribute_prediction.epoch (
    run_id       int NOT NULL REFERENCES attribute_prediction.model_run (run_id) ON DELETE CASCADE,
    epoch        int NOT NULL,                         -- partial key
    train_loss   double precision,
    val_loss     double precision,
    val_macro_f1 double precision,                     -- NULL for regression runs
    PRIMARY KEY (run_id, epoch)
);
