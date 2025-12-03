class USkylineEnforcerFollowComponent : UActorComponent
{
	UPROPERTY(DefaultComponent)
	UBasicAICharacterMovementComponent MoveComp;

	USkylineEnforcerDeployComponent DeployComp;
	USceneComponent Target;
	AHazeActor HazeOwner;
	bool bHasReset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		DeployComp = USkylineEnforcerDeployComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);
	}

	void Follow(ASkylineHighwayCombatIsland InActor)
	{
		TArray<AActor> AttachedActors;
		InActor.GetAttachedActors(AttachedActors, false, true);
		ASkylineHighwayCarDynamic Dynamic = nullptr;
		for(AActor AttachedActor : AttachedActors)
		{
			Dynamic = Cast<ASkylineHighwayCarDynamic>(AttachedActor);
			if(Dynamic != nullptr)
				break;
		}
		if(Dynamic != nullptr)
			Target = Dynamic.ConeRotateComp;
		else
			Target = InActor.RootComponent;

		MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
		MoveComp.FollowComponentMovement(Target, this, Priority = EInstigatePriority::Normal);

		HazeOwner.AddActorCollisionBlock(this);
		HazeOwner.BlockCapabilities(n"Falling", this);
		HazeOwner.BlockCapabilities(n"KillAtRange", this);
		HazeOwner.BlockCapabilities(BasicAITags::ControlSideSwitch, this);
		
		UMovementGravitySettings::SetGravityScale(HazeOwner, 0, this);
		InActor.OnFinishedMove.AddUFunction(this, n"FinishedMove");
		InActor.OnCompletedFinishedMove.AddUFunction(this, n"CompletedFinishedMove");
		bHasReset = false;
		DeployComp.bShouldDeploy = true;

		Owner.SetActorControlSide(Target);
	}

	UFUNCTION()
	private void FinishedMove(int SplineIndex)
	{
		DeployComp.bShouldDeploy = false;
	}

	UFUNCTION()
	private void CompletedFinishedMove(int SplineIndex)
	{
		Reset();
		Unfollow();
	}

	void Unfollow()
	{
		Target = nullptr;
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
		Reset();
	}

	private void Reset()
	{
		if(bHasReset)
			return;
		HazeOwner.RemoveActorCollisionBlock(this);
		HazeOwner.UnblockCapabilities(n"Falling", this);
		HazeOwner.UnblockCapabilities(n"KillAtRange", this);
		HazeOwner.UnblockCapabilities(BasicAITags::ControlSideSwitch, this);
		UMovementGravitySettings::ClearGravityScale(HazeOwner, this);
		bHasReset = true;
	}
}