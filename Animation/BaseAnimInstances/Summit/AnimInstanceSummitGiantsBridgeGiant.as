
class UAnimInstanceSummitGiantsBridgeGiant : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BridgeGiantEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData BridgeGiantMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FHazeAcceleratedVector LookAtLocationHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FVector LookAtLocationEyes;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	float LookAtAlpha = 0;

	UAnimGiantsLookAtComponent LookAtComp;
	bool bEnabled;
	float Radius;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		LookAtComp = UAnimGiantsLookAtComponent::GetOrCreate(HazeOwningActor);
		Radius = 12000;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (LookAtComp == nullptr)
			return;

		if (GetAnimTrigger(n"LookAtEnable"))
			bEnabled = true;
		if (GetAnimTrigger(n"LookAtDisable"))
		{
			bEnabled = false;
			Radius = 7000;
		}

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(false, LookAtLocationHead, LookAtLocationEyes, DeltaTime, Radius = Radius, ClampPitchMin = -10);
		LookAtAlpha = bHasValidTarget && bEnabled ? 1 : 0;
	}
}