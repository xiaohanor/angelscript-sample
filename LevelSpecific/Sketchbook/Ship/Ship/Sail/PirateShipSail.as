event void FSailRolledDownSignature();

UCLASS(Abstract)
class APirateShipSail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SailMeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RolledSailMeshComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RolledSailMeshComp2;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent InteractionComp1;

	UPROPERTY(DefaultComponent)
	UThreeShotInteractionComponent InteractionComp2;

	UPROPERTY()
	FHazeTimeLike RollDownSailTimeLike;
	default RollDownSailTimeLike.UseSmoothCurveZeroToOne();

	UPROPERTY()
	float RolledUpScaleHeight = 0.1;

	UPROPERTY()
	float RolledUpScaleDepth = 0.3;

	UPROPERTY()
	FSailRolledDownSignature OnSailRolledDown;

	bool bKnot1Untied = false;
	bool bKnot2Untied = false;
	private bool bRolledDown = false;

	FVector RolledUpScale;
	FVector RolledDownScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp1.OnInteractionStarted.AddUFunction(this, n"StartUntieInteraction");
		InteractionComp2.OnInteractionStarted.AddUFunction(this, n"StartUntieInteraction");

		RollDownSailTimeLike.BindUpdate(this, n"RollDownSailTimeLikeUpdate");
		RollDownSailTimeLike.BindFinished(this, n"RollDownSailTimeLikeFinished");

		RolledDownScale = SailMeshComp.GetWorldScale();
		RolledUpScale = FVector(RolledUpScaleDepth, RolledDownScale.Y, RolledUpScaleHeight);
		SailMeshComp.SetWorldScale3D(RolledUpScale);
	}

	UFUNCTION()
	private void StartUntieInteraction(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		auto PlayerComp = UPirateShipSailPlayerComponent::Get(Player);
		PlayerComp.Sail = this;
		PlayerComp.InteractionComp = InteractionComponent;
		PlayerComp.bIsUnrolling = true;
	}

	void FinishUntieInteraction(UInteractionComponent InteractionComponent)
	{
		if(InteractionComponent == InteractionComp1)
			UntieKnot1();
		else if(InteractionComponent == InteractionComp2)
			UntieKnot2();
	}

	private void UntieKnot1()
	{
		InteractionComp1.Disable(this);
		RolledSailMeshComp1.SetHiddenInGame(true, true);
		bKnot1Untied = true;

		if (bKnot2Untied)
			RollDownSail();
	}

	private void UntieKnot2()
	{
		InteractionComp2.Disable(this);
		RolledSailMeshComp2.SetHiddenInGame(true, true);
		bKnot2Untied = true;

		if (bKnot1Untied)
			RollDownSail();
	}


	void RollDownSail()
	{
		if(bRolledDown || RollDownSailTimeLike.IsPlaying())
			return;

		if(!bKnot1Untied)
		{
			InteractionComp1.Disable(this);
			RolledSailMeshComp1.SetHiddenInGame(true, true);
			bKnot1Untied = true;
		}

		if(!bKnot2Untied)
		{
			InteractionComp2.Disable(this);
			RolledSailMeshComp2.SetHiddenInGame(true, true);
			bKnot2Untied = true;
		}

		RollDownSailTimeLike.Play();
	}

	UFUNCTION()
	private void RollDownSailTimeLikeUpdate(float CurrentValue)
	{
		SailMeshComp.SetWorldScale3D(Math::Lerp(RolledUpScale, RolledDownScale, CurrentValue));
	}

	UFUNCTION()
	private void RollDownSailTimeLikeFinished()
	{
		bRolledDown = true;
		OnSailRolledDown.Broadcast();
	}

	bool IsRolledDown() const
	{
		return bRolledDown;
	}
};