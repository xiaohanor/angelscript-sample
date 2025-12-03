
class USkylineTorHammerWhipGrabBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineTorHammerComponent HammerComp;
	USkylineTorSettings Settings;
	bool bGrabbed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HammerComp = USkylineTorHammerComponent::GetOrCreate(Owner);
		Settings = USkylineTorSettings::GetSettings(Owner);

		UGravityWhipResponseComponent WhipResponse = UGravityWhipResponseComponent::GetOrCreate(Owner);
		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnThrown.AddUFunction(this, n"Thrown");
	}

	UFUNCTION()
	private void Thrown(UGravityWhipUserComponent UserComponent,
	                    UGravityWhipTargetComponent TargetComponent, FHitResult HitResult,
	                    FVector Impulse)
	{
		bGrabbed = false;
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent,
	                       UGravityWhipTargetComponent TargetComponent,
	                       TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		HammerComp.SetMode(ESkylineTorHammerMode::Whipped);
		bGrabbed = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!bGrabbed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!bGrabbed)
			return true;
		return false;
	}
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bGrabbed = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
	}
}