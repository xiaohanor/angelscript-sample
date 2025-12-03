
UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Tundra_TreeGuardian_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnRootsHitSurface(FTundraPlayerTreeGuardianRangedHitSurfaceEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnRangedGrappleBlocked(){}

	UFUNCTION(BlueprintEvent)
	void OnRangedGrappleReachedPoint(){}

	UFUNCTION(BlueprintEvent)
	void OnRangedGrappleStartedEnter(FTundraPlayerTreeGuardianRangedGrappleEnterEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartGrowingInRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnStartGrowingOutRangedInteractionRoots(FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepAudio_Release(FTundraPlayerTreeGuardianAudioFootstepParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepAudio_Plant_Left(FTundraPlayerTreeGuardianAudioFootstepParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLifeGivingStopped(FTundraPlayerTreeGuardianLifeGivingEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLifeGivingStarted(FTundraPlayerTreeGuardianLifeGivingEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnNonRangedLifeGivingHandsTouchEarth(){}

	UFUNCTION(BlueprintEvent)
	void OnFootstepAudio_Plant_Right(FTundraPlayerTreeGuardianAudioFootstepParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnLifeGivingEntering(FTundraPlayerTreeGuardianLifeGivingEffectParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnFootstep(FTundraPlayerTreeGuardianOnFootstepParams Params){}

	/* END OF AUTO-GENERATED CODE */

	private USkeletalMeshComponent TreeSkelMesh;
	private UTundraPlayerShapeshiftingComponent ShapeShiftComp;
	private UPlayerMovementAudioComponent PlayerMovementAudioComp;
	private UHazeMovementComponent MoveComp;
	private UPlayerSlideComponent SlideComp;

	private FVector LastLeftHandLocation;
	private FVector LastRightHandLocation;

	private FVector LastNeckLocation;
	private FVector LastHipLocation;

	private FVector LastTreeLocation;

	private FVector CachedLeftHandVelo;
	private FVector CachedRightHandVelo;
	private FVector CachedNeckVelo;
	private FVector CachedHipVelo;

	const float MAX_HAND_VELO = 30.0;
	const float MAX_NECK_VELO = 25.0;
	const float MAX_HIP_VELO = 20.0;
	
	private bool bWasSliding = false;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintEvent)
	void OnSlidingStart(bool bIsIceSlide) {};

	UFUNCTION(BlueprintEvent)
	void OnSlidingStop() {};

	bool GetbIsInTreeGuardianShape() const property
	{
		return ShapeShiftComp.IsBigShape();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return bIsInTreeGuardianShape;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !bIsInTreeGuardianShape;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MovementAudio::RequestBlock(this, PlayerMovementAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestBlock(this, PlayerMovementAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestBlock(this, PlayerMovementAudioComp, EMovementAudioFlags::Falling);

		ProxyEmitterSoundDef::LinkToActor(this, Game::GetZoe());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MovementAudio::RequestUnBlock(this, PlayerMovementAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestUnBlock(this, PlayerMovementAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestUnBlock(this, PlayerMovementAudioComp, EMovementAudioFlags::Falling);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		TreeSkelMesh = USkeletalMeshComponent::Get(HazeOwner);
		Player = Game::GetZoe();
		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		PlayerMovementAudioComp = UPlayerMovementAudioComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FVector TreeVelo = HazeOwner.GetActorLocation() - LastTreeLocation;	

		const FVector LeftHandLocation = TreeSkelMesh.GetSocketLocation(MovementAudio::TundraTreeGuardian::LeftHandSocketName);
		CachedLeftHandVelo = (LeftHandLocation - LastLeftHandLocation) - TreeVelo;

		const FVector RightHandLocation = TreeSkelMesh.GetSocketLocation(MovementAudio::TundraTreeGuardian::RightHandSocketName);
		CachedRightHandVelo = (RightHandLocation - LastRightHandLocation) - TreeVelo;

		LastLeftHandLocation = LeftHandLocation;
		LastRightHandLocation = RightHandLocation;

		const FVector NeckLocation = TreeSkelMesh.GetSocketLocation(MovementAudio::TundraTreeGuardian::NeckSocketName);
		CachedNeckVelo = (NeckLocation - LastNeckLocation) - TreeVelo;		
		LastNeckLocation = NeckLocation;

		const FVector HipLocation = TreeSkelMesh.GetSocketLocation(MovementAudio::TundraTreeGuardian::HipSocketName);
		CachedHipVelo = (HipLocation - LastHipLocation) - TreeVelo;
		LastHipLocation = HipLocation;

		LastTreeLocation = HazeOwner.GetActorLocation();

		QuerySliding();
	}

	private void QuerySliding()
	{
		const bool bIsSliding = MoveComp.IsOnAnyGround() && SlideComp.IsSlideActive();
		if(bIsSliding && !bWasSliding)
		{
			FHazeTraceSettings TraceSettings = Trace::InitFromPlayer(Player);
			TraceSettings.IgnoreActor(HazeOwner);
			TraceSettings.IgnoreActor(Player);
			auto PhysMat = AudioTrace::GetPhysMaterialFromHit(MoveComp.GroundContact.ConvertToHitResult(), TraceSettings);		
			
			bool bIsIceSlide = false;
			if(PhysMat != nullptr)
			{
				bIsIceSlide = PhysMat.Name.ToString().Contains("Ice");
			}
			
			OnSlidingStart(bIsIceSlide);
			
		}
		else if(!bIsSliding && bWasSliding)
		{
			OnSlidingStop();
		}

		bWasSliding = bIsSliding;
	}

	UFUNCTION(BlueprintPure)
	void GetLifeGivingInput(UTundraLifeReceivingComponent LifeComp, float&out Horizontal, float&out Vertical)
	{
		
		Horizontal = 0;
		Vertical = 0;
		
		if(LifeComp != nullptr)
		{
			if(LifeComp.IsHorizontalAlphaEnabled())
				Horizontal = LifeComp.HorizontalAlpha;

			if(LifeComp.IsVerticalAlphaEnabled())
				Vertical = LifeComp.VerticalAlpha;

		}		
	}

	UFUNCTION(BlueprintPure)
	void GetHandRelativeVelocitiesNormalized(float&out Left, float&out Right)
	{
		Left = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HAND_VELO), FVector2D(0.0, 1.0), CachedLeftHandVelo.Size());
		Right = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HAND_VELO), FVector2D(0.0, 1.0), CachedRightHandVelo.Size());
	}

	UFUNCTION(BlueprintPure)
	float GetRelativeHipVelocityNormalized()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_HIP_VELO), FVector2D(0.0, 1.0), CachedHipVelo.Size());
	}

	UFUNCTION(BlueprintPure)
	float GetRelativeNeckVelocityNormalized()
	{
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_NECK_VELO), FVector2D(0.0, 1.0), CachedNeckVelo.Size());
	}
}