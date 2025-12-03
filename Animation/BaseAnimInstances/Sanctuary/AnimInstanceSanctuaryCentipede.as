class UAnimInstanceSanctuaryCentipede : UHazeAnimInstanceBase
{
	// ------------------------- ANIMATIONS ------------------------- //

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Mh;
    UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Movement;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData BiteMovement;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Locomotion")
    FHazePlayBlendSpaceData Swinging;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Override")
    FHazePlaySequenceData Bite;
    UPROPERTY(BlueprintReadOnly, Category = "Animations|Override")
    FHazePlaySequenceData CanBite;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Override")
    FHazePlayRndSequenceData BiteBody;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Override")
    FHazePlayBlendSpaceData EdgeTiltBS;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Additive")
    FHazePlayBlendSpaceData BodyEdgeTiltBS;
	UPROPERTY(BlueprintReadOnly, Category = "Animations|Override")
    FHazePlayRndSequenceData Shooting;


	UPROPERTY(BlueprintReadOnly, Category = "Animations|Additive")
	FHazePlayBlendSpaceData SmallLegs;


	// ------------------------- OTHER CENTIPEDE VARIABLES ------------------------- //

	ACentipede Centipede;

	// [DON'T TOUCH] Eman code: holds bones we update from code
	UPROPERTY(BlueprintReadOnly)
	private TArray<FName> BoneWhitelist;

	const float HeadForwardOffset = 20;

	bool bMioWasPassingProjectile = false;
	bool bZoeWasPassingProjectile = false;

	int bMioPreviousNumPassingProjectiles = 0;
	int bZoePreviousNumPassingProjectiles = 0;

	// ------------------------- COMPONENTS ------------------------- //

	UPlayerMovementComponent MioMoveComp, ZoeMoveComp;
	UPlayerCentipedeComponent MioCentipedeComponent, ZoeCentipedeComponent;
	UCentipedeBiteComponent MioBiteComponent, ZoeBiteComponent;
	UPlayerCentipedeSwingComponent MioSwingComponent, ZoeSwingComponent;


	// ------------------------- SPEED VARIABLES ------------------------- //

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D MioVelocity;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D ZoeVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D MioSmallLegsVelocity;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D ZoeSmallLegsVelocity;

	float MioSpeed;
	float ZoeSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsMoving;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsMoving;


	// ------------------------- TURN RATE VARIABLES ------------------------- //

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MioTurnRate;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ZoeTurnRate;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MioBodyMoveYaw;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ZoeBodyMoveYaw;


	// ------------------------- BITE OVERRIDE VARIABLES ------------------------- //

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsBiting;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsBiting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsBitingSomething;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsBitingSomething;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MioBiteAlpha;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ZoeBiteAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsInBitingRange;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsInBitingRange;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MioCanBiteAlpha;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ZoeCanBiteAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioBite;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeBite;

	UPROPERTY(BlueprintReadOnly)
	bool bMioIsPlayingBiteAnim;

	UPROPERTY(BlueprintReadOnly)
	bool bZoeIsPlayingBiteAnim;

	// ------------------------- SHOOTING VARIABLES ------------------------- //

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioHasShootTarget;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeHasShootTarget;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsPassingFood;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsPassingFood;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsShooting;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsShootingWater;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsShootingWater;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioIsBitingWater;
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeIsBitingWater;

	UPROPERTY(BlueprintReadOnly)
	bool bMioIsPlayingShootAnim;
	UPROPERTY(BlueprintReadOnly)
	bool bZoeIsPlayingShootAnim;

	// ------------------------- SWINGING VARIABLES ------------------------- //

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioSwinging;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bMioBitingSwing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeSwinging;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bZoeBitingSwing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MioSwingDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ZoeSwingDirection;



	// ------------------------- FOOT TRACE ------------------------- //

	UPROPERTY(BlueprintReadOnly)
	TArray<FName> MioFeet;

	UPROPERTY(BlueprintReadOnly)
	TArray<FName> ZoeFeet;

	UPROPERTY(BlueprintReadOnly)
	TArray<float> MioFeetAlpha;
	
	UPROPERTY(BlueprintReadOnly)
	TArray<float> ZoeFeetAlpha;

	int MioCachedFootTraceIndex;
	int ZoeCachedFootTraceIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D MioEdgeTilt; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D ZoeEdgeTilt; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MioEdgeLegsDirection;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ZoeEdgeLegsDirection;

	// Trace down 'radius' units + fucking weird gremlin bias
	const float SATANS_OFFSET = 10.0;
	const float FEET_TRACE_LENGHT = 200.0 + SATANS_OFFSET;



	void TraceFeet(AActor Actor, const TArray<FName> &FeetSocketName, TArray<float> &FeetAlpha, int &CachedFootTraceIndex)
	{

		CachedFootTraceIndex = Math::WrapIndex(CachedFootTraceIndex + 1, 0, FeetSocketName.Num());
		FName TraceBoneName = FeetSocketName[CachedFootTraceIndex];

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		TraceSettings.IgnoreActor(HazeOwningActor);
		// TODO (make sure it doesnt hit centipedehead) TraceSettings.IgnoreActor(CentipedeHead);

		FVector TraceBoneLocation = OwningComponent.GetSocketLocation(TraceBoneName);

		FVector TraceStartPos = Math::LinePlaneIntersection(TraceBoneLocation,
													   TraceBoneLocation - Actor.ActorUpVector,
													   Actor.ActorLocation,
													   Actor.ActorUpVector);

		FHitResult TraceHitResult = TraceSettings.QueryTraceSingle(TraceStartPos, TraceStartPos - Actor.ActorUpVector * FEET_TRACE_LENGHT);
		FeetAlpha[CachedFootTraceIndex] = !TraceHitResult.bBlockingHit ? 1 : 0;

		
		//Debug::DrawDebugSphere(Location - test * 30);
	}

	void UpdateEdgeBodyTilt(FVector2D &EdgeTilt, const TArray<float> FeetAlpha, float &LegDirection)
	{
		EdgeTilt = FVector2D::ZeroVector;
		LegDirection = 0;
		for (int Index = 0; Index < FeetAlpha.Num(); Index++)
		{
			if(FeetAlpha[Index] == 1)
			{
				// Left
				if (Index % 2 == 0)
				{
					EdgeTilt.X -= 1;
				}
				// Right
				else
				{
					EdgeTilt.X += 1;
				}
				if (Index < 2) // Front
				{
					EdgeTilt.Y += 1;
				}
				else if (Index > 3)	// Back
				{
					EdgeTilt.Y -= 1;
				}
				
			}
		}

		LegDirection = EdgeTilt.Y; // Do we not want the middle bones to count?

		if (FeetAlpha[2] == 1)
			EdgeTilt.Y *= 1.5;
		if (FeetAlpha[3] == 1)
			EdgeTilt.Y *= 1.5;

	}

	// ------------------------- EVENT GRAPH ------------------------- //




	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		Centipede = Cast<ACentipede>(HazeOwningActor);

		MioMoveComp = UPlayerMovementComponent::Get(Game::Mio);
		ZoeMoveComp = UPlayerMovementComponent::Get(Game::Zoe);

		MioFeetAlpha.SetNumZeroed(MioFeet.Num());
		ZoeFeetAlpha.SetNumZeroed(ZoeFeet.Num());
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (Centipede == nullptr)
			return;

		// Setup bones we want to poke
		for (FName BoneName : BoneWhitelist)
		{
			FHazeModifyBoneData& BoneData = GetOrAddModifyBoneData(BoneName);

			BoneData.TranslationMode = EHazeBoneModificationMode::Mode_Replace;
			BoneData.TranslationSpace = EBoneControlSpace::BCS_WorldSpace;

			BoneData.RotationMode = EHazeBoneModificationMode::Mode_Replace;
			BoneData.RotationSpace = EBoneControlSpace::BCS_WorldSpace;

			BoneData.ScaleMode = EHazeBoneModificationMode::Mode_Ignore;
		}
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Centipede == nullptr)
			return;

		if (Centipede.Segments.IsEmpty())
			return;

		if (Centipede.bIsControlledByCutscene)
			return;

		MioCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Mio);
		ZoeCentipedeComponent = UPlayerCentipedeComponent::Get(Game::Zoe);

		MioBiteComponent = UCentipedeBiteComponent::Get(Game::Mio);
		ZoeBiteComponent = UCentipedeBiteComponent::Get(Game::Zoe);

		MioSwingComponent = UPlayerCentipedeSwingComponent::Get(Game::Mio);
		ZoeSwingComponent = UPlayerCentipedeSwingComponent::Get(Game::Zoe);

		// Speed
		MioVelocity = Game::Mio.IsPlayerDead() ? FVector2D::ZeroVector : FVector2D(Game::Mio.GetActorLocalVelocity().Y, Game::Mio.GetActorLocalVelocity().X);
		ZoeVelocity = Game::Zoe.IsPlayerDead() ? FVector2D::ZeroVector : FVector2D(Game::Zoe.GetActorLocalVelocity().Y, Game::Zoe.GetActorLocalVelocity().X);

		MioSpeed = MioVelocity.Size();
		ZoeSpeed = ZoeVelocity.Size();

		if (MioSpeed > 10)
			bMioIsMoving = true;
		else
			bMioIsMoving = false;

		if (ZoeSpeed > 10)
			bZoeIsMoving = true;
		else
			bZoeIsMoving = false;

		MioSmallLegsVelocity = MioMoveComp.SyncedMovementInputForAnimationOnly.Size() > 0 ? MioVelocity : FVector2D::ZeroVector;
		ZoeSmallLegsVelocity = ZoeMoveComp.SyncedMovementInputForAnimationOnly.Size() > 0 ? ZoeVelocity : FVector2D::ZeroVector;

		// Turn rate
		MioTurnRate = MioMoveComp.GetMovementYawVelocity(false) / 230.0;
		ZoeTurnRate = ZoeMoveComp.GetMovementYawVelocity(false) / 230.0;

		// Bite
		//bMioIsBiting = MioBiteComponent.IsBiting();
		//bZoeIsBiting = ZoeBiteComponent.IsBiting();

		bMioIsBitingSomething = MioBiteComponent.IsBitingSomething();
		bZoeIsBitingSomething = ZoeBiteComponent.IsBitingSomething();


		bMioHasShootTarget = MioCentipedeComponent.bAutoTargeting;
		bZoeHasShootTarget = ZoeCentipedeComponent.bAutoTargeting;

		// note(Ylva) previous way, only checked if any projectile was traveling rather than number of projectiles
		// bMioIsShooting = bMioWasPassingProjectile && !MioCentipedeComponent.bPassingProjectile;
		// bZoeIsShooting = bZoeWasPassingProjectile && !ZoeCentipedeComponent.bPassingProjectile;
		bMioIsShooting = bMioPreviousNumPassingProjectiles > MioCentipedeComponent.NumPassingProjectiles;
		if (bMioIsShooting)
			bMioIsPlayingShootAnim = true;

		bZoeIsShooting = bZoePreviousNumPassingProjectiles > ZoeCentipedeComponent.NumPassingProjectiles;
		if (bZoeIsShooting)
			bZoeIsPlayingShootAnim = true;

		bMioBite = CheckValueChangedAndSetBool(bMioIsBiting, IsPlayerBiting(MioSwingComponent, MioBiteComponent), EHazeCheckBooleanChangedDirection::FalseToTrue) || bMioIsShooting;
		if (bMioBite)
			bMioIsPlayingBiteAnim = true;

		bZoeBite = CheckValueChangedAndSetBool(bZoeIsBiting, IsPlayerBiting(ZoeSwingComponent, ZoeBiteComponent), EHazeCheckBooleanChangedDirection::FalseToTrue) || bZoeIsShooting;
		if (bZoeBite)
			bZoeIsPlayingBiteAnim = true;

		// if (bZoeIsShooting)
		// 	PrintToScreen("Zoe Shooting!", 2.0);

		// if (bMioIsShooting)
		// 	PrintToScreen("Mio Shooting!", 2.0);

		bMioWasPassingProjectile = MioCentipedeComponent.bPassingProjectile;
		bZoeWasPassingProjectile = ZoeCentipedeComponent.bPassingProjectile;

		bMioPreviousNumPassingProjectiles = MioCentipedeComponent.NumPassingProjectiles;
		bZoePreviousNumPassingProjectiles = ZoeCentipedeComponent.NumPassingProjectiles;

		bMioIsPassingFood = MioCentipedeComponent.bPassingProjectile;
		bZoeIsPassingFood = ZoeCentipedeComponent.bPassingProjectile;

		bMioIsShootingWater = MioCentipedeComponent.bShootingWater;

		if (bMioIsBiting)
			MioBiteAlpha = Math::FInterpConstantTo(MioBiteAlpha, 1, DeltaTime, 22);
		else
			MioBiteAlpha = Math::FInterpTo(MioBiteAlpha, 0, DeltaTime, 12);

		if (bZoeIsBiting)
			ZoeBiteAlpha = Math::FInterpConstantTo(ZoeBiteAlpha, 1, DeltaTime, 22);
		else
			ZoeBiteAlpha = Math::FInterpTo(ZoeBiteAlpha, 0, DeltaTime, 12);

		// Bite in range
		bMioIsInBitingRange = MioBiteComponent.IsInBitingRange();
		bZoeIsInBitingRange = ZoeBiteComponent.IsInBitingRange();

		if (bMioIsInBitingRange)
			MioCanBiteAlpha = Math::FInterpTo(MioCanBiteAlpha, 1, DeltaTime, 10);
		else
			MioCanBiteAlpha = Math::FInterpTo(MioCanBiteAlpha, 0, DeltaTime, 10);

		if (bZoeIsInBitingRange)
			ZoeCanBiteAlpha = Math::FInterpTo(ZoeCanBiteAlpha, 1, DeltaTime, 10);
		else
			ZoeCanBiteAlpha = Math::FInterpTo(ZoeCanBiteAlpha, 0, DeltaTime, 10);


		// Swing
		bMioSwinging = MioSwingComponent.IsSwinging();
		bMioBitingSwing = MioSwingComponent.IsBitingSwingPoint();
		bZoeSwinging = ZoeSwingComponent.IsSwinging();
		bZoeBitingSwing = ZoeSwingComponent.IsBitingSwingPoint();

		// Turn rate

		// Get alignment angle
		MioBodyMoveYaw = MioCentipedeComponent.Centipede.GetPlayerAngleRelativeToBody(Game::Mio, 6);
		ZoeBodyMoveYaw = ZoeCentipedeComponent.Centipede.GetPlayerAngleRelativeToBody(Game::Zoe, 6);

		ModifyBones();

		if (!bMioSwinging && !bMioBitingSwing)
		{
			TraceFeet(Game::Mio, MioFeet, MioFeetAlpha, MioCachedFootTraceIndex);
			UpdateEdgeBodyTilt(MioEdgeTilt, MioFeetAlpha, MioEdgeLegsDirection);
		}
		else
		{
			for (int i = 0; i < MioFeetAlpha.Num(); i++)
			{
				MioFeetAlpha[i] = 0;
			}
			MioEdgeTilt = FVector2D::ZeroVector;
			MioEdgeLegsDirection = 0;
		}

		if (!bZoeSwinging && !bZoeBitingSwing)
		{
			TraceFeet(Game::Zoe, ZoeFeet, ZoeFeetAlpha, ZoeCachedFootTraceIndex);
			UpdateEdgeBodyTilt(ZoeEdgeTilt, ZoeFeetAlpha, ZoeEdgeLegsDirection);
		}	
		else
		{
			for (int i = 0; i < ZoeFeetAlpha.Num(); i++)
			{
				ZoeFeetAlpha[i] = 0;
			}
			ZoeEdgeTilt = FVector2D::ZeroVector;
			ZoeEdgeLegsDirection = 0;
		}
		
		if (bMioSwinging)
			MioSwingDirection = MioMoveComp.SyncedMovementInputForAnimationOnly.X;
		else if (bMioBitingSwing)
			MioSwingDirection = 0;
		if (bZoeSwinging)
			ZoeSwingDirection = ZoeMoveComp.SyncedMovementInputForAnimationOnly.X;
		else if (bZoeBitingSwing)
			ZoeSwingDirection = 0;

#if EDITOR

/*

		Print("bMioIsBiting: " + bMioIsBiting, 0.f);
		Print("MioBiteAlpha: " + MioBiteAlpha, 0.f);
	Print("bZoeIsInBitingRange: " + bZoeIsInBitingRange, 0.f);
	Print("bZoeIsBiting: " + bZoeIsBiting, 0.f);
		Print("bMioSwinging: " + bMioSwinging, 0.f);
		Print("bMioBitingSwing: " + bMioBitingSwing, 0.f);
*/

#endif
    }

	bool IsPlayerBiting(UPlayerCentipedeSwingComponent SwingComponent, UCentipedeBiteComponent BiteComponent) const
	{
		// We want to delay biting if this is a swing bite
		if (SwingComponent.IsBitingSwingPoint())
		{
			float TimeSinceActivation = Time::GameTimeSeconds - SwingComponent.GetLastActivationTimeStamp();
			return TimeSinceActivation >= 0.1;
			
		}
		else
		{
			return BiteComponent.IsBiting();
		}
	}

	void ModifyBones()
	{
		// This unholy var is directly linked to the amount of "special"
		// immovable bones, we don't want to mess around with those so we skip them.
		// See Centipede.as' "SpecialBoneCount"
		const uint SegmentOffset = 2;

		for (int i = 0; i < BoneWhitelist.Num(); i++)
		{
			FTransform BoneTransform;
			if (i == 0) // Head - GreenHead - Mio
			{
				BoneTransform = GetHeadTransformForPlayer(Centipede::GetHeadPlayer());
			}
			else if (i == BoneWhitelist.Num() - 1) // Head - BlueHead - Zoe
			{
				BoneTransform = GetHeadTransformForPlayer(Centipede::GetTailPlayer());
			}
			else
			{
				// Where in body are we
				const int Index = Math::Clamp(i - 1, 0, BoneWhitelist.Num() - 2);
				const float Fraction = Math::Saturate(Index / (BoneWhitelist.Num() - 3.0));

				// Get location from centipede segments
				FVector Location = Centipede.Segments[i + SegmentOffset].WorldLocation;

				// Get forward vector
				FVector PreviousBoneLocation = Centipede.Segments[i - 1 + SegmentOffset].WorldLocation;
				FVector NextBoneLocation = Centipede.Segments[i + 1 + SegmentOffset].WorldLocation;
				FVector ForwardVector = (PreviousBoneLocation - NextBoneLocation).GetSafeNormal();

				// Just lerp from end to end, works better than expected
				FVector UpVector = Math::Lerp(Centipede::GetHeadPlayer().MeshOffsetComponent.UpVector, Centipede::GetTailPlayer().MeshOffsetComponent.UpVector, Fraction);
				UpVector.Normalize();

				// Make rotation
				FQuat Rotation = FQuat::MakeFromXZ(ForwardVector, UpVector);

				// Add vertical offset
				Location += UpVector * Centipede::SegmentRadius;

				// Bam!
				BoneTransform = FTransform(Rotation, Location);
			}

			FHazeModifyBoneData& ModifyBoneData = GetOrAddModifyBoneData(BoneWhitelist[i]);
			ModifyBoneData.Translation = BoneTransform.Translation;
			ModifyBoneData.Rotation = BoneTransform.Rotator();
		}
	}

	FTransform GetHeadTransformForPlayer(AHazePlayerCharacter Player)
	{
		// Get location from player
		FVector Location = Player.MeshOffsetComponent.WorldLocation;
		Location -= Player.MeshOffsetComponent.UpVector * SATANS_OFFSET; // ?!

		FQuat Rotation = Player.MeshOffsetComponent.ComponentQuat;

		FTransform HeadTransform = FTransform(Rotation, Location);
		return HeadTransform;
	}

	UFUNCTION()
	void AnimNotify_MioStopBite()
	{
		bMioIsPlayingBiteAnim = false;
	}

	UFUNCTION()
	void AnimNotify_ZoeStopBite()
	{
		bZoeIsPlayingBiteAnim = false;
	}

	UFUNCTION()
	void AnimNotify_MioStopShoot()
	{
		bMioIsPlayingShootAnim = false;	
	}

	UFUNCTION()
	void AnimNotify_ZoeStopShoot()
	{
		bZoeIsPlayingShootAnim = false;	
	}
}