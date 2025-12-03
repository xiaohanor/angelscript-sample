
UCLASS(Abstract)
class UGameplay_Character_Creature_Player_Tundra_Fairy_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnFootstepTrace_Plant(FPlayerFootstepParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnExitMoveSpline(){}

	UFUNCTION(BlueprintEvent)
	void OnEnterMoveSpline(FTundraPlayerFairyMoveSplineEnterParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnEndLeapSession(){}

	UFUNCTION(BlueprintEvent)
	void OnLeaped(FTundraPlayerFairyLeapParams Params){}

	UFUNCTION(BlueprintEvent)
	void OnJumped(){}

	UFUNCTION(BlueprintEvent)
	void OnStartLeapSession(){}

	/* END OF AUTO-GENERATED CODE */

	float CachedRelativeWingSpeed;
	float CachedRelativeWingSpeedDelta;

	float LastWingSpeed;

	FVector LastLeftWingLocation;
	FVector LastRightWingLocation;
	FVector LastFairyLocation;

	const float MAX_WING_SPEED = 600;
	const float MAX_CAMERA_DISTANCE = 1000;

	USkeletalMeshComponent FairyMesh;

	private bool bWasSliding = false;

	UHazeMovementComponent MoveComp;
	UPlayerSlideComponent SlideComp;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadWrite, Category = "Wings")
	float WingsGainMultiplier = 1.0;

	UPROPERTY(BlueprintReadWrite, Category = "Move Splines")
	ATundraFairyMoveSpline ActiveMoveSpline = nullptr;

	private UTundraPlayerShapeshiftingComponent ShapeShiftComp;

	bool GetbIsInFairyShape() const property
	{
		return ShapeShiftComp.IsSmallShape();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return bIsInFairyShape;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !bIsInFairyShape;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto MoveAudioComp = UHazeMovementAudioComponent::Get(Player);

		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestBlock(this, MoveAudioComp, EMovementAudioFlags::Falling);

		ProxyEmitterSoundDef::LinkToActor(this, Game::GetZoe());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		auto MoveAudioComp = UHazeMovementAudioComponent::Get(Player);

		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Breathing);
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Efforts);
		MovementAudio::RequestUnBlock(this, MoveAudioComp, EMovementAudioFlags::Falling);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		auto Fairy = Cast<ATundraPlayerFairyActor>(HazeOwner);
		Player = Fairy.Player;	

		FairyMesh = USkeletalMeshComponent::Get(Fairy);

		ShapeShiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		SlideComp = UPlayerSlideComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent)
	void OnSlidingStart(bool bIsIceSlide) {};

	UFUNCTION(BlueprintEvent)
	void OnSlidingStop() {};

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!IsInMoveSpline())
		{
			const FVector FairyLocation = HazeOwner.GetActorLocation();
			const FVector FairyVelo = FairyLocation - LastFairyLocation;

			FVector LeftWingLocation = FairyMesh.GetSocketLocation(n"LeftWingAudioSocket");
			const FVector RightWingLocation = FairyMesh.GetSocketLocation(n"RightWingAudioSocket");

			FVector LeftWingForwardVelo = (LeftWingLocation - LastLeftWingLocation).ConstrainToPlane(FVector::UpVector);
			FVector RightWingForwardVelo = (RightWingLocation - LastRightWingLocation).ConstrainToPlane(FVector::UpVector);
			
			const float RelativeLeftWingVeloSpeed = (LeftWingForwardVelo - FairyVelo.ConstrainToPlane(FVector::UpVector)).Size() / DeltaSeconds;	
			const float RelativeRightWingVeloSpeed = (RightWingForwardVelo - FairyVelo).Size() / DeltaSeconds;

			const float WantedWingMovement = Math::Max(RelativeLeftWingVeloSpeed, RelativeRightWingVeloSpeed);
			const float CurrWingSpeed = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_WING_SPEED), FVector2D(0.0, 1.0), WantedWingMovement);

			CachedRelativeWingSpeedDelta = CurrWingSpeed - CachedRelativeWingSpeed;
			CachedRelativeWingSpeed = CurrWingSpeed;

			LastLeftWingLocation = LeftWingLocation;
			LastRightWingLocation = RightWingLocation;
			LastFairyLocation = FairyLocation;

			WingsGainMultiplier = Math::FInterpTo(WingsGainMultiplier, 1.0, DeltaSeconds, 3.0);
		}	

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
	void GetRelativeWingsMovement(float&out Speed, float&out Delta)
	{
		Speed = CachedRelativeWingSpeed;
		Delta = CachedRelativeWingSpeedDelta;		
	}

	UFUNCTION(BlueprintPure)
	float GetCameraDistanceNormalized()
	{
		const FVector CameraPos = Player.GetViewLocation();
		const float CameraDist = CameraPos.Distance(HazeOwner.GetActorLocation());
		return Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_CAMERA_DISTANCE), FVector2D(0.0, 1.0), CameraDist);
	}

	UFUNCTION(BlueprintPure)
	bool IsInMoveSpline() 
	{
		return ActiveMoveSpline != nullptr;
	}

	UFUNCTION(BlueprintPure)
	float GetSplineProgression()
	{
		if(IsInMoveSpline())
		{
			FSplinePosition SplinePos = ActiveMoveSpline.Spline.GetClosestSplinePositionToWorldLocation(HazeOwner.GetActorLocation());
			return SplinePos.CurrentSplineDistance / ActiveMoveSpline.Spline.SplineLength;
		}

		return 0.0;
	}

}