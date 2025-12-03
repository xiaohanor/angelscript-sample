class USkylineEnforcerJumpEntranceBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Weapon); 

	USkylineEnforcerJumpEntranceComponent JumpEntranceComp;
	UBasicAIRuntimeSplineComponent SplineComp;
	ASkylineEnforcerJumpEntranceScenepoint ScenepointActor;
	UScenepointComponent Scenepoint;
	UBasicAICharacterMovementComponent MoveComp;
	USkylineEnforcerSettings Settings;
	bool bAtScenepoint;
	bool bJump;
	bool bLanded;
	float JumpEndTime;
	float CompleteTime = BIG_NUMBER;
	float Distance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JumpEntranceComp = USkylineEnforcerJumpEntranceComponent::GetOrCreate(Owner);
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
		Settings = USkylineEnforcerSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		JumpEntranceComp.bCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(JumpEntranceComp.bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(JumpEntranceComp.bCompleted)
			return true;
		if(ActiveDuration > CompleteTime)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if(JumpEntranceComp.Scenepoints.Num() == 0)
		{
			JumpEntranceComp.bCompleted = true;
			return;
		}

		bAtScenepoint = false;
		Scenepoint = nullptr;
		CompleteTime = BIG_NUMBER;
		bLanded = false;
		bJump = false;
		bAtScenepoint = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if(Scenepoint != nullptr)
			Scenepoint.Release(Owner);
		Owner.ClearSettingsByInstigator(this);

		if((ScenepointActor != nullptr) && (ScenepointActor.LinkedScenepoints.Num() > 0))
			JumpEntranceComp.Scenepoints = ScenepointActor.LinkedScenepoints;
		else
			JumpEntranceComp.bCompleted = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Scenepoint == nullptr)
		{
			for(ASkylineEnforcerJumpEntranceScenepoint JumpScenepointActor: JumpEntranceComp.Scenepoints)
			{
				UScenepointComponent ScenepointCandidate = JumpScenepointActor.GetScenepoint();
				if(ScenepointCandidate.CanUse(Owner))
				{
					ScenepointActor = JumpScenepointActor;
					Scenepoint = ScenepointCandidate;
					Scenepoint.Use(Owner);
					break;
				}
			}
			return;
		}

		if(bLanded)
			return;

		if(bJump)
		{
			if(ActiveDuration > JumpEndTime)
			{
				AnimComp.ClearAnimationMove(LocomotionFeatureAISkylineTags::JumpEntrance);

				if(MoveComp.HasGroundContact())
				{
					AnimComp.RequestSubFeature(SubTagEnforcerJumpEntrance::Land, this);
					float LandDuration = Cast<ULocomotionFeatureAIEnforcerJumpEntrance>(AnimComp.GetFeatureByClass(ULocomotionFeatureAIEnforcerJumpEntrance)).AnimData.Land.Sequence.PlayLength;
					CompleteTime = ActiveDuration + LandDuration - 0.1;
					bLanded = true;
					UBasicAIMovementSettings::ClearUseTeleportingAnimationMovement(Owner, this);
				}
			}
			else
			{
				DestinationComp.RotateInDirection(Scenepoint.WorldRotation.ForwardVector);
			}
			return;			
		}

		if(bAtScenepoint)
		{
			SplineComp.MoveAlongSpline(500);
			if(SplineComp.IsNearEndOfSpline(1))
			{
				bJump = true;
				UBasicAIMovementSettings::SetUseTeleportingAnimationMovement(Owner, true, this);
				FVector JumpStartMove = Scenepoint.WorldRotation.ForwardVector * ScenepointActor.JumpDistance + Scenepoint.UpVector * Settings.JumpEntranceHeight;
				AnimComp.RequestFeature(LocomotionFeatureAISkylineTags::JumpEntrance, EBasicBehaviourPriority::Medium, this, 0, JumpStartMove);

				auto Feature = AnimComp.GetFeatureByClass(ULocomotionFeatureAIEnforcerJumpEntrance);
				auto JumpFeature = Cast<ULocomotionFeatureAIEnforcerJumpEntrance>(Feature);
				float JumpStartDuration = JumpFeature.AnimData.Start.Sequence.PlayLength;
				JumpEndTime = ActiveDuration + JumpStartDuration - 0.2;

				Scenepoint.Release(Owner);
			}
			return;
		}

		DestinationComp.MoveTowards(Scenepoint.Owner.ActorLocation, 1500);
		if(Scenepoint.IsAt(Owner))
		{
			bAtScenepoint = true;
			SplineComp.SetSplineBetweenActors(Owner, Scenepoint.Owner);
		}
	}	
}