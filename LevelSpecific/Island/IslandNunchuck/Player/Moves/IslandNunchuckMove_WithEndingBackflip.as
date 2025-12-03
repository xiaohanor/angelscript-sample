
class UIslandNunchuckTargetWithEndingBackflipMoveAsset : UIslandNunchuckMoveAssetBase
{	
	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidatePlayerGroundedType = false;

	// Respond to the players grounded status
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidatePlayerGroundedType"))
	EIslandNunchuckGroundedSettingsType PlayerGroundedType = EIslandNunchuckGroundedSettingsType::Grounded;

	UPROPERTY(Category = "Settings", meta = (InlineEditConditionToggle))
	bool bValidateTargetableGroundedType = false;

	// Respond to the targetable components 'GroundedType' setting
	UPROPERTY(Category = "Settings", meta = (EditCondition = "bValidateTargetableGroundedType"))
	EIslandNunchuckGroundedSettingsType TargetableGroundedType = EIslandNunchuckGroundedSettingsType::Grounded; 

	// Do we need a distance to the target to trigger
	UPROPERTY(Category = "Settings")
	FHazeRange RequiredDistanceToTarget = FHazeRange(-1, -1);

	// How long will we stay at the target until we let go
	UPROPERTY(Category = "Animation|Settings")
	float LockedToTargetTime = 0.0;

	UPROPERTY(Category = "Animation|Settings")
	float BlendTime = 0.1;

	UPROPERTY(Category = "Animation|Settings")
	float StartTime = 0;

	UPROPERTY(Category = "Animation")
	FIslandNunchuckAnimationData MoveToAnimation;

	UPROPERTY(Category = "Animation")
	FIslandNunchuckAnimationData AttackAnimation;
}

struct FIslandNunchuckTargetWithEndingBackflipMoveActivation
{
	UIslandNunchuckTargetableComponent Target;
	UIslandNunchuckTargetWithEndingBackflipMoveAsset Move;
}

class UIslandNunchuckTargetWithEndingBackflipCapability : UHazeChildCapability
{
 	default CapabilityTags.Add(n"Nunchuck");
 	default DebugCategory = n"Nunchuck";

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UPlayerIslandNunchuckUserComponent MeleeComp;
	UPlayerTargetablesComponent TargetContainer;
	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionSettings AirMotionSettings;
 	USteppingMovementData Movement;

	AHazePlayerCharacter Player;
	UIslandNunchuckTargetWithEndingBackflipMoveAsset ActiveMove;
	UIslandNunchuckTargetableComponent Target;

	FIslandNunchuckAnimationData ActiveAnimationData;
	float ActivePlayLength = 0;

	float CurrentSpeed = 0.0;
	FVector CurrentMovementDirection = FVector::ZeroVector;
	bool bMovingToTarget = false;
	bool bHasAttachedToTarget = false;

	EIslandNunchuckGroundedSettingsType PlayerTriggerType;
	FVector ReleaseMovementDirection = FVector::ZeroVector;
	FVector ReleaseMovementLocation = FVector::ZeroVector;
	FVector GroundedTriggerLocation = FVector::ZeroVector;

	FIslandNunchuckPendingImpactData PendingImpacts;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MeleeComp = UPlayerIslandNunchuckUserComponent::Get(Player);
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AirMotionSettings = UPlayerAirMotionSettings::GetSettings(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandNunchuckTargetWithEndingBackflipMoveActivation& Activation) const
	{
		if(MeleeComp.NoValidTargetMoveAssets.Num() == 0)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.5))
			return false;
		
		if(MeleeComp.IsNunchuckInputBlocked())
			return false;

		if(MeleeComp.IsInBlockedActionWindow())
			return false;

		// We need to have a primary target to trigger
		auto PrimTarget = TargetContainer.GetPrimaryTarget(UIslandNunchuckTargetableComponent);
		if(PrimTarget == nullptr)
			return false;

		if(!PrimTarget.bCanTraversToTarget)
			return false;

		// Player grounded type
		TArray<EIslandNunchuckGroundedSettingsType> ValidPlayerGroundedTypes;
		if(MoveComp.IsOnAnyGround())
			ValidPlayerGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
		else
			ValidPlayerGroundedTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);


		// Targetable component required grounded type
		TArray<EIslandNunchuckGroundedSettingsType> ValidTargetableTypes;
		if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::Grounded)
		{
			ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
		}
		else if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::Flying)
		{
			ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
		}
		else if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::AirAndGround)
		{
			if(MoveComp.IsOnAnyGround())
				ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
			else	
				ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
		}
		else if(PrimTarget.GroundedType == EIslandNunchuckMeleeTargetableType::MoveCompStatus)
		{
			auto TargetMoveComp = UHazeMovementComponent::Get(PrimTarget.Owner);
			if(TargetMoveComp != nullptr)
			{
				if(TargetMoveComp.IsOnAnyGround())
					ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::Grounded);
				else	
					ValidTargetableTypes.Add(EIslandNunchuckGroundedSettingsType::InAir);
			}
			else
			{
				devError(f"Target point on {PrimTarget.Owner} has type 'MoveCompStatus' but no movement component");
			}
		}

		EIslandNunchuckMoveAssetPriority HighestPriority = EIslandNunchuckMoveAssetPriority::Default;

		const float TargetDistance = MeleeComp.GetAttackDistanceToTarget(PrimTarget);
		TArray<UIslandNunchuckTargetWithEndingBackflipMoveAsset> FinalAvailableAsset;
		for(auto It : MeleeComp.AirTargetWithEndingBackflipAssets)
		{
			if(It == nullptr)
				continue;

			if(It.Priority < HighestPriority)
				continue;

			if(It.bValidatePlayerGroundedType && !ValidPlayerGroundedTypes.Contains(It.PlayerGroundedType))
				continue;

			if(It.bValidateTargetableGroundedType && !ValidTargetableTypes.Contains(It.TargetableGroundedType))
				continue;

			if(TargetDistance < It.RequiredDistanceToTarget.Min && It.RequiredDistanceToTarget.Min >= 0)
				continue;

			if(TargetDistance > It.RequiredDistanceToTarget.Max && It.RequiredDistanceToTarget.Max >= 0)
				continue;

			if(!PrimTarget.ValidateTags(It.Tags))
				continue;

			if(It.Priority > HighestPriority)
			{
				FinalAvailableAsset.Reset();
				HighestPriority = It.Priority;
			}
						
			FinalAvailableAsset.Add(It);
		}

		if(FinalAvailableAsset.Num() == 0)
			return false;

		int ActivationIndex = -1;
		UIslandNunchuckTargetWithEndingBackflipMoveAsset Move;
		while(true)
		{
			ActivationIndex = Math::RandRange(0, FinalAvailableAsset.Num() - 1);
			Move = FinalAvailableAsset[ActivationIndex];
			
			// Make sure we dont activate the same move if we have more to pick from
			if(FinalAvailableAsset.Num() == 1 || !MeleeComp.WasMoveRecentlyActivated(Move))
				break;
		}

		Activation.Target = PrimTarget;
		Activation.Move = FinalAvailableAsset[Math::RandRange(0, FinalAvailableAsset.Num() - 1)];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveMove == nullptr)
			return true;

		if(Target == nullptr)
			return true;

		if(!ActiveAnimationData.IsValidForPlayer())
			return true;

		if(ActivePlayLength > ActiveAnimationData.GetMovePlayLength())
		{
			return true;	
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandNunchuckTargetWithEndingBackflipMoveActivation Activation)
	{
		bMovingToTarget = true;
		CurrentSpeed = MoveComp.HorizontalVelocity.Size();
		CurrentMovementDirection = Player.ActorForwardVector;

		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		
		ActiveMove = Activation.Move;
		Target = Activation.Target;

		MeleeComp.SetActiveMove(ActiveMove, Target, this);
		ActivateMoveToAnimation();
		PendingImpacts.Setup(ActiveMove, ActiveMove.AttackAnimation);

		if(MoveComp.IsOnAnyGround())
		{
			PlayerTriggerType = EIslandNunchuckGroundedSettingsType::Grounded;
			GroundedTriggerLocation = MoveComp.GroundContact.Location;
		}
		else
			PlayerTriggerType = EIslandNunchuckGroundedSettingsType::InAir;	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bHasAttachedToTarget)
		{
			bHasAttachedToTarget = false;
			Player.DetachFromActor();
		}

		if(ActiveAnimationData.PlayerAnimation.Sequence != nullptr)
			MeleeComp.PlayerOwner.StopSlotAnimationByAsset(ActiveAnimationData.PlayerAnimation.Sequence);

		if(ActiveAnimationData.WeaponAnimation.Sequence != nullptr)
			MeleeComp.Weapon.StopSlotAnimationByAsset(ActiveAnimationData.WeaponAnimation.Sequence);
		
		ActiveAnimationData = FIslandNunchuckAnimationData();
		Player.ClearActorTimeDilation(this);
		MeleeComp.Weapon.ClearActorTimeDilation(this);
		MeleeComp.ClearActiveMove(this);
		ActiveMove = nullptr;

		ActivePlayLength = 0;
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			Movement.IgnoreActorForThisFrame(Target.Owner);

			if(bMovingToTarget)
			{
				ApplyMoveToTargetMovement(DeltaTime);
			}
			else
			{
				ApplyReachedTargetMovement(DeltaTime);
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"AirMovement");
		}
	}

	void ActivateMoveToAnimation()
	{
		const FIslandNunchuckAnimationData PrevActiveAnimationData = ActiveAnimationData;

		ActivePlayLength = 0;
		ActiveAnimationData = ActiveMove.MoveToAnimation;

		// Validate that we have an animtion and a valid length
		check(ActiveAnimationData.IsValidForPlayer());

		FHazeSlotAnimSettings Settings;
		Settings.PlayRate = ActiveAnimationData.GetPlayRateToReachExpectedAnimationLength();
		Settings.BlendType = EHazeBlendType::BlendType_Inertialization;
		Settings.BlendTime = ActiveMove.BlendTime;
		Settings.StartTime = ActiveMove.StartTime;

		if(ActiveAnimationData.IsValidForPlayerAndWeapon())
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.PlaySlotAnimation(ActiveAnimationData.WeaponAnimation.Sequence, Settings);
		}
		else
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.StopSlotAnimationByAsset(PrevActiveAnimationData.WeaponAnimation.Sequence);
		}
	}

	void ActivateAttackAnimation()
	{
		const FIslandNunchuckAnimationData PrevActiveAnimationData = ActiveAnimationData;

		ActivePlayLength = 0;
		ActiveAnimationData = ActiveMove.AttackAnimation;

		// Validate that we have an animtion and a valid length
		check(ActiveAnimationData.IsValidForPlayer());

		FHazeSlotAnimSettings Settings;
		Settings.PlayRate = ActiveAnimationData.GetPlayRateToReachExpectedAnimationLength();
		Settings.BlendType = EHazeBlendType::BlendType_Inertialization;
		Settings.BlendTime = ActiveMove.BlendTime;
		Settings.StartTime = ActiveMove.StartTime;

		if(ActiveAnimationData.IsValidForPlayerAndWeapon())
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.PlaySlotAnimation(ActiveAnimationData.WeaponAnimation.Sequence, Settings);
		}
		else
		{
			MeleeComp.PlayerOwner.PlaySlotAnimation(ActiveAnimationData.PlayerAnimation.Sequence, Settings);
			MeleeComp.Weapon.StopSlotAnimationByAsset(PrevActiveAnimationData.WeaponAnimation.Sequence);
		}
	}


	void ApplyMoveToTargetMovement(float DeltaTime)
	{
		if(HasControl())
		{	
			CurrentSpeed = Math::FInterpConstantTo(CurrentSpeed, AirMotionSettings.HorizontalMoveSpeed * 5, DeltaTime, AirMotionSettings.HorizontalVelocityInterpSpeed);
			
			FVector DeltaToTarget = Target.GetOwner().GetActorLocation() - Player.GetActorLocation();
			FVector DirToTarget = DeltaToTarget.GetSafeNormal();
			float PendingMoveAmount = CurrentSpeed * DeltaTime;

			float DistanceToTarget = DeltaToTarget.Size();
			DistanceToTarget = DistanceToTarget - Target.KeepDistance - MoveComp.GetCollisionCapsuleRadius() - 10;

			FRotator WantedRotation = DirToTarget.ToOrientationRotator();
			WantedRotation = Math::RInterpTo(Player.GetActorRotation(), WantedRotation, DeltaTime, 10);
		 	Movement.SetRotation(WantedRotation);

			// We are going to reach the target this frame
			if(DistanceToTarget < PendingMoveAmount)
			{	
				//Movement.AddDeltaWithCustomVelocity(DirToTarget * DistanceToTarget, DirToTarget * CurrentSpeed);
				ActivateAttackAnimation();
				bMovingToTarget = false;

				bHasAttachedToTarget = true;
				const FVector OriginalScale = Player.GetActorScale3D();
				Player.AttachToComponent(Target, NAME_None, EAttachmentRule::KeepWorld);
				Player.SetActorScale3D(OriginalScale);
				Player.SetActorLocation(Target.WorldLocation);
				
			}
			else
			{
				Movement.AddVelocity(DirToTarget * CurrentSpeed);
			}
		}
		else
		{
		 	Movement.ApplyCrumbSyncedAirMovement();
		}
	}

	void ApplyReachedTargetMovement(float DeltaTime)
	{
		ActivePlayLength += DeltaTime;

		if(HasControl())
		{
			PendingImpacts.Update(ActivePlayLength, MeleeComp);
		
			if(ActivePlayLength > ActiveMove.LockedToTargetTime)
			{
				// Make sure we are no longer attached to the target
				// and setup all the release params
				if(bHasAttachedToTarget)
				{
					ReleaseMovementDirection = -Player.GetActorForwardVector();
					ReleaseMovementLocation = Player.GetActorLocation();
					bHasAttachedToTarget = false;
					Player.DetachFromActor();
				}

				// If this was triggered from the air, we just move backwards
				if(PlayerTriggerType == EIslandNunchuckGroundedSettingsType::InAir)
				{
					float Alpha = 0.5 + ((ActivePlayLength - ActiveMove.LockedToTargetTime) / 0.5);
					Movement.AddVelocity(ReleaseMovementDirection * AirMotionSettings.HorizontalMoveSpeed * Alpha);
				}	

				// else, we make sure we move back to where we jumped of from. So we don't fall the ground of and die
				else
				{
					float Alpha = (ActivePlayLength - ActiveMove.LockedToTargetTime) / (ActiveAnimationData.GetMovePlayLength() - ActiveMove.LockedToTargetTime);
					FVector WatedLocation = Math::Lerp(ReleaseMovementLocation, GroundedTriggerLocation, Alpha);
			
					FVector DeltaToLocation = WatedLocation - Player.GetActorLocation();
					DeltaToLocation = DeltaToLocation.VectorPlaneProject(MoveComp.WorldUp);

					Movement.AddDeltaWithCustomVelocity(DeltaToLocation, DeltaToLocation.GetSafeNormal() * AirMotionSettings.HorizontalMoveSpeed);
					Movement.SetRotation((-DeltaToLocation).ToOrientationRotator());
				}
			}
		}
		else
		{
			Movement.ApplyCrumbSyncedAirMovement();
		}
	}

}