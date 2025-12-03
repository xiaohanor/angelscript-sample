
class UAnimInstanceSummitGiantsFemaleClimbing : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ClimbUp;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ClimbUpMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData TransportPlayers;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData TransportPlayersMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FHazeAcceleratedVector LookAtLocationHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FVector LookAtLocationEyes;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	float LookAtAlpha;

	bool bEnabled;
	UAnimGiantsLookAtComponent LookAtComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		LookAtComp = UAnimGiantsLookAtComponent::GetOrCreate(HazeOwningActor);
		bEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LookAtComp == nullptr)
			return;

		if (!bEnabled && GetAnimTrigger(n"LookAtEnable"))
			bEnabled = true;

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(false, LookAtLocationHead, LookAtLocationEyes, DeltaTime);
		LookAtAlpha = bEnabled && bHasValidTarget ? 1 : 0;
	}
}