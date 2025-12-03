
class UAnimInstanceSummitGiantsHangingLedge : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HangingLedgeEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData HangingLedgeMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FHazeAcceleratedVector LookAtLocationHead;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	FVector LookAtLocationEyes;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "LookAt")
	float LookAtAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayerAttached;

	bool bMioAttached;
	bool bZoeAttached;
	bool bEnabled;

	UAnimGiantsLookAtComponent LookAtComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
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

		const int PlayerAttached = GetAnimIntParam(n"PlayerAttached", true);
		{
			if (PlayerAttached == 1)
				bMioAttached = true;
			else if (PlayerAttached == 2)
				bZoeAttached = true;

			UpdateForceLookAtActor();
		}

		const int PlayerDetached = GetAnimIntParam(n"PlayerDetached", true);
		if (PlayerDetached != 0)
		{
			if (PlayerDetached == 1)
				bMioAttached = false;
			else if (PlayerDetached == 2)
				bZoeAttached = false;

			UpdateForceLookAtActor();
		}

		bPlayerAttached = bMioAttached || bZoeAttached;

		const bool bHasValidTarget = LookAtComp.GetLookAtLocation(true,
																  LookAtLocationHead,
																  LookAtLocationEyes,
																  DeltaTime,
																  bPlayerAttached ? 1 : 4,
																  Radius = 9500,
																  ClampPitchMin = -10);
		LookAtAlpha = bEnabled && bHasValidTarget ? 1 : 0;
	}

	void UpdateForceLookAtActor()
	{
		if (!bMioAttached && !bZoeAttached)
			LookAtComp.ForceLookAtActor = nullptr;
		else if (bMioAttached && !bZoeAttached)
			LookAtComp.ForceLookAtActor = Game::Mio;
		else if (bZoeAttached && !bMioAttached)
			LookAtComp.ForceLookAtActor = Game::Zoe;
	}
}