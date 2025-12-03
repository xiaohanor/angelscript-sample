// This capability should be refactored into two.
class USummitDecimatorTopdownSpinBalconyCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Gameplay;

	USummitDecimatorTopdownSettings Settings;
	USummitDecimatorTopdownPhaseComponent PhaseComp;
	UBasicAIAnimationComponent AnimComp;
	UMeshComponent MeshComp;
	AActor ArenaCenterScenePoint;
	UHazeCrumbSyncedRotatorComponent CrumbArenaCenterRotator; 

	AAISummitDecimatorTopdown Self;	
	float TurnDuration = 0;
	float SpinRate;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USummitDecimatorTopdownSettings::GetSettings(Owner);
		PhaseComp = USummitDecimatorTopdownPhaseComponent::Get(Owner);
		AnimComp = UBasicAIAnimationComponent::Get(Owner);
		MeshComp = UMeshComponent::Get(Owner);
		CrumbArenaCenterRotator = UHazeCrumbSyncedRotatorComponent::GetOrCreate(Owner, n"ArenaCenterRotator");
		ArenaCenterScenePoint = Owner.AttachmentRootActor;
		Self = Cast<AAISummitDecimatorTopdown>(Owner);
		SpinRate = Settings.SpinBalconyRotationRate;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return false;

		if (PhaseComp.CurrentPhase > 2)
			return false;

		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::StartRotatingBalcony) // Set MoveState to Running
			return true;

		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Idle)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PhaseComp.CurrentState != ESummitDecimatorState::RunningAttackSequence)
			return true;
		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::StopRotatingBalcony)
			return true;
		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Idle)
			return true;
		if (PhaseComp.CurrentPhase > 2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{	
		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Idle) // might activate after pausing for attack and then we want to keep the turn outward MoveState.
			PhaseComp.CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::TurningOutwards;		

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PrintToScreen("Activated Substate: Spin Balcony", 5.0, Color=FLinearColor::Yellow);
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::StopRotatingBalcony)
		{
			PhaseComp.TryActivateNextAttackState();
			PhaseComp.CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::Idle;
		}
		AnimComp.ClearFeature(this);

		// Toggle direction
		Self.SpinningDir = -Self.SpinningDir;

		TurnDuration = 0;
		SpinRate = Settings.SpinBalconyRotationRate;  // reset spin rate
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (PhaseComp.CurrentPhase > 2 || PhaseComp.CurrentState == ESummitDecimatorState::Idle || PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Idle)
			return;

		FVector CenterDir = (ArenaCenterScenePoint.ActorLocation - Owner.ActorLocation);
		CenterDir.Z = 0;
		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::TurningOutwards) // Turning outwards
		{
			// Setting rotation towards circle tangent.
			DecimatorTopdown::Animation::RequestFeatureTurn(AnimComp, this);
			FVector LeftTangentDir = CenterDir.CrossProduct(FVector::UpVector) * Self.SpinningDir;
			FVector NewDir = Owner.ActorForwardVector.RotateTowards(LeftTangentDir, Settings.DecimatorTurnRate * DeltaTime);
			Owner.SetActorRotation(NewDir.Rotation());
			TurnDuration += DeltaTime;
			Self.bIsTurningOutward = true;
			PhaseComp.RemainingTurnDuration = Math::Clamp(90 / Settings.DecimatorTurnRate - TurnDuration, 0.0, 1.0); // for auto-aim prediction
			if (TurnDuration > 90 /Settings.DecimatorTurnRate)
			{
				PhaseComp.CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::Running;
				TurnDuration = 0;
				Self.bIsTurningOutward = false;
			}
		}
		else if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::TurningInwards)
		{
			// Turning towards center
			DecimatorTopdown::Animation::RequestFeatureTurnJump(AnimComp, this);
			TurnDuration += DeltaTime;
			if (TurnDuration > (90 / Settings.DecimatorTurnRate) * 0.5)  // Delay turning to match jump animation
			{
				FVector NewDir = Owner.ActorForwardVector.RotateTowards(CenterDir, Settings.DecimatorTurnRate * 3 * DeltaTime); // Speed up turn rate for turn jump animation
				Owner.SetActorRotation(NewDir.Rotation());
				SpinRate = 1.75 * Settings.SpinBalconyRotationRate; // Increase spin rate as a jump impulse
			}
			
			if (TurnDuration > 90 / Settings.DecimatorTurnRate)
			{
				PhaseComp.CurrentBalconyMoveState = ESummitDecimatorBalconyMoveState::PausingForAttack;
				TurnDuration = 0;
				SpinRate = Settings.SpinBalconyRotationRate; // reset spin rate
			}
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't move unless running or turn jumping
		if (PhaseComp.CurrentBalconyMoveState != ESummitDecimatorBalconyMoveState::Running && PhaseComp.CurrentBalconyMoveState != ESummitDecimatorBalconyMoveState::TurningInwards)
			return;

		// Running
		PhaseComp.RemainingTurnDuration = 0.0;
		if (PhaseComp.CurrentBalconyMoveState == ESummitDecimatorBalconyMoveState::Running)
			DecimatorTopdown::Animation::RequestFeatureLocomotion(AnimComp, this);

		// Move around arena
		if (HasControl())
		{
			FRotator RotationRate(0, SpinRate * Self.SpinningDir, 0);
			ArenaCenterScenePoint.AddActorLocalRotation(RotationRate * DeltaTime);
			CrumbArenaCenterRotator.SetValue(ArenaCenterScenePoint.GetActorRotation());
		}
		else
		{
			ArenaCenterScenePoint.SetActorRotation(CrumbArenaCenterRotator.Value);
		}

		// Skip to next attack state
		if (PhaseComp.GetCurrentAttackState() == ESummitDecimatorAttackState::StartRotatingBalcony)
			PhaseComp.TryActivateNextAttackState();
	}
};