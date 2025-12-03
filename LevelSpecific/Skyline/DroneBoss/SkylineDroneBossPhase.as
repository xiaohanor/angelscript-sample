class USkylineDroneBossPhase : UDataAsset
{
	// How many attachments we can spawn for the left attachment, zero indicates infinite until phase is finished.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Left Attachment")
	int LeftAttachmentSpawnAmount = 0;

	// Delay between attachment respawns for the left attachment.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Left Attachment")
	float LeftAttachmentSpawnDelay = 2.0;

	// Duration of attachment spawn and lock-in for the left attachment.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Left Attachment")
	float LeftAttachmentSpawnDuration = 1.5;

	// Curve evaluated for attach animation during spawn of the left attachment.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Left Attachment")
	UCurveFloat LeftSpawnCurve;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Left Attachment")
	TSubclassOf<ASkylineDroneBossAttachment> LeftAttachmentClass;

	// How many attachments we can spawn for the right attachment, zero indicates infinite until phase is finished.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Right Attachment")
	int RightAttachmentSpawnAmount = 0;

	// Delay between attachment respawns for the right attachment.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Right Attachment")
	float RightAttachmentSpawnDelay = 2.0;

	// Duration of attachment spawn and lock-in for the right attachment.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Right Attachment")
	float RightAttachmentSpawnDuration = 1.5;

	// Curve evaluated for attach animation during spawn of the right attachment.
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Right Attachment")
	UCurveFloat RightSpawnCurve;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Phase|Right Attachment")
	TSubclassOf<ASkylineDroneBossAttachment> RightAttachmentClass;
}