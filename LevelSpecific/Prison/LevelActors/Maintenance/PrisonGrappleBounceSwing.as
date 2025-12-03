UCLASS(Abstract)
class APrisonGrappleBounceSwing : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent BounceActorAttachmentRoot;

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Grapple Bounce Swing")
	APrisonGrappleBounce BounceActor;

	UPROPERTY(EditAnywhere, Category = "Grapple Bounce Swing")
	const bool bStartUp = true;

	UPROPERTY(EditDefaultsOnly)
	float FlipDuration = 0.25;

	UPROPERTY(EditInstanceOnly)
	TArray<APrisonGrappleBounceSwing> PairedSwings;

	TPerPlayer<float> UnblockGrappleTime;

	// We use start times to make syncing between the players easier
	// The highest start time is used for both sides, meaning that it will always be synced
	// even if both players spam bounce on the actors, since both players just send a time to each other.
	bool bHasEverFlipped = false;
	float FlipUpStartTime = -1;
	float FlipDownStartTime = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BounceActor.InitializeGrapplePointLocation();
		BounceActor.AttachToComponent(BounceActorAttachmentRoot, NAME_None, EAttachmentRule::KeepWorld);

		float Pitch = Math::Lerp(-90, 0, GetFlipAlpha());
		RotationRoot.SetRelativeRotation(FRotator(Pitch, 0, 0));

		BounceActor.ConditionDelegate.BindUFunction(this, n"BounceTargetCondition");
		BounceActor.OnPlayerBounced.AddUFunction(this, n"OnPlayerBounced");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Game::Players)
		{
			if(UnblockGrappleTime[Player] > 0 && Time::GameTimeSeconds > UnblockGrappleTime[Player])
			{
				Player.UnblockCapabilities(PlayerMovementTags::Grapple, this);
				UnblockGrappleTime[Player] = -1;
			}
		}

		float Pitch = Math::Lerp(-90, 0, GetFlipAlpha());
		RotationRoot.SetRelativeRotation(FRotator(Pitch, 0, 0));
	}

	bool IsUp() const
	{
		if(!bHasEverFlipped)
			return bStartUp;

		if(FlipUpStartTime > FlipDownStartTime)
			return true;
		else
			return false;
	}

	bool IsFlipped() const
	{
		return IsUp() != bStartUp;
	}

	float GetFlipStartTime() const
	{
		if(!bHasEverFlipped)
			return -FlipDuration;

		if(FlipUpStartTime > FlipDownStartTime)
		{
			return FlipUpStartTime;
		}
		else
		{
			return FlipDownStartTime;
		}
	}

	/**
	 * 1 is Up
	 * 0 is Down
	 */
	float GetFlipAlpha() const
	{
		float FlipTime = GetFlipStartTime();
		float FlipAlpha = Math::GetPercentageBetweenClamped(FlipTime, FlipTime + FlipDuration, Time::PredictedGlobalCrumbTrailTime);
		if(!IsUp())
			FlipAlpha = 1.0 - FlipAlpha;

		return FlipAlpha;
	}

	UFUNCTION()
	private bool BounceTargetCondition()
	{
		if(GetFlipAlpha() < 1.0 - KINDA_SMALL_NUMBER)
			return false;

		return true;
	}

	UFUNCTION()
	private void OnPlayerBounced(AHazePlayerCharacter Player)
	{
		// Only handle the bounce on the player control side
		if(!Player.HasControl())
			return;

		Player.BlockCapabilities(PlayerMovementTags::Grapple, this);
		UnblockGrappleTime[Player] = Time::GameTimeSeconds + 0.2;

		NetFlipAtTime(!IsFlipped(), Time::PredictedGlobalCrumbTrailTime + 0.1);
	}

	UFUNCTION(NetFunction)
	private void NetFlipAtTime(bool bIsFlipped, float InStartFlipTime)
	{
		SetIsFlipped(bIsFlipped, InStartFlipTime);

		for(auto PairedSwing : PairedSwings)
			PairedSwing.SetIsFlipped(bIsFlipped, InStartFlipTime);
	}

	void SetIsFlipped(bool bIsFlipped, float InStartFlipTime)
	{
		bHasEverFlipped = true;

		bool bFlipUp = bIsFlipped;
		if(bStartUp)
			bFlipUp = !bFlipUp;

		if(bFlipUp)
			FlipUpStartTime = InStartFlipTime;
		else
			FlipDownStartTime = InStartFlipTime;
	}
};