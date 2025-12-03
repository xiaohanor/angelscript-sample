class USkylineDroneBossBeamPhase : USkylineDroneBossPhase
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attachment")
	TSubclassOf<ASkylineDroneBossBeamRing> RingType;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attachment")
	float OrbitSpeed = 10.0;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Attachment")
	float RingActivationDelay = 3.0;
}