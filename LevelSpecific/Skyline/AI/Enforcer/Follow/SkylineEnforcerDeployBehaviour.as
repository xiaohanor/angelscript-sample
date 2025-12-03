
class USkylineEnforcerDeployBehaviour : UBasicBehaviour
{
	USkylineEnforcerDeployComponent DeployComp;
	USkylineEnforcerFollowComponent FollowComp;
	FVector PreviousLocation;
	FVector Velocity;
	bool bSetVelocity = false;
	AHazeCharacter Character;

	float WaitTime;
	float WaitDuration = 0.25;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DeployComp = USkylineEnforcerDeployComponent::GetOrCreate(Owner);
		FollowComp = USkylineEnforcerFollowComponent::GetOrCreate(Owner);
		Character = Cast<AHazeCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!DeployComp.bShouldDeploy)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DeployComp.bDeploying = true;
		Owner.AddActorCollisionBlock(this);
		WaitTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DeployComp.bDeploying = false;
		Owner.RemoveActorCollisionBlock(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WaitTime > SMALL_NUMBER)
		{
			if(Time::GetGameTimeSince(WaitTime) > WaitDuration)
				DeactivateBehaviour();
			return;
		}

		if(!DeployComp.bShouldDeploy)
			WaitTime = Time::GameTimeSeconds;
	}
}