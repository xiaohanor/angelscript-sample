class UCoastJetskiDeployBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	float DeploySide = 0.0;
	UCoastJetskiSettings Settings;
	UCoastJetskiComponent JetskiComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastJetskiSettings::GetSettings(Owner);
		JetskiComp = UCoastJetskiComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!Settings.bDeployEnabled)
			return false;
		if (JetskiComp.bHasDeployed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.DeployDuration)
			return true;
		if ((JetskiComp.Submersion > 0.0) && (ActiveDuration > Settings.DeployDuration * 0.25))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		DeploySide = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > Settings.DeployDuration * 0.25)
			JetskiComp.bHasDeployed = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!JetskiComp.RailPosition.IsValid())
			return;
		FVector OwnLoc = Owner.ActorLocation;
		
		// Should we deploy left or right?
		if (DeploySide == 0.0)
			DeploySide = (JetskiComp.RailPosition.WorldRightVector.DotProduct(OwnLoc - JetskiComp.RailPosition.WorldLocation) > 0.0) ? 1.0 : -1.0;

		if (ActiveDuration < Settings.DeployPushDuration)
		{
			FVector Push = Settings.DeployPush / Settings.DeployPushDuration;
			FVector DeployPush = JetskiComp.RailPosition.WorldRightVector * DeploySide * Push.Y; 
			DeployPush += JetskiComp.RailPosition.WorldForwardVector * Push.X;		
			DeployPush += JetskiComp.RailPosition.WorldUpVector * Push.Z;		
			DestinationComp.AddCustomAcceleration(DeployPush);
		}	
	}
}
