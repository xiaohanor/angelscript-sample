class USkylineTorHammerStateManager : UActorComponent
{
	private UGravityWhipSlingAutoAimComponent WhipAimComp;
	private UGravityBladeCombatTargetComponent BladeTargetComp;
	private UGravityBladeGrappleComponent BladeGrappleComp;
	private UGravityWhipTargetComponent WhipTargetComp;;

	private TInstigated<bool> WhipAimCompEnabled;
	private TInstigated<bool> BladeTargetCompEnabled;
	private TInstigated<bool> BladeGrappleCompEnabled;
	private TInstigated<bool> WhipTargetCompEnabled;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WhipAimComp = UGravityWhipSlingAutoAimComponent::GetOrCreate(Owner);
		WhipAimComp.Disable(this);
		BladeTargetComp = UGravityBladeCombatTargetComponent::GetOrCreate(Owner);
		BladeTargetComp.Disable(this);
		BladeGrappleComp = UGravityBladeGrappleComponent::GetOrCreate(Owner);
		BladeGrappleComp.Disable(this);
		WhipTargetComp = UGravityWhipTargetComponent::GetOrCreate(Owner);
		WhipTargetComp.Disable(this);
	}

	// WhipAim
	void EnableWhipAim(FInstigator Instigator)
	{
		WhipAimCompEnabled.Apply(true, Instigator);
		WhipAimComp.Enable(this);
	}

	void ClearWhipAim(FInstigator Instigator)
	{
		WhipAimCompEnabled.Clear(Instigator);
		if(!WhipAimCompEnabled.Get())
			WhipAimComp.Disable(this);
	}

	// Blade Target
	void EnableBladeTargetComp(FInstigator Instigator)
	{
		BladeTargetCompEnabled.Apply(true, Instigator);
		BladeTargetComp.Enable(this);
	}

	void ClearBladeTargetComp(FInstigator Instigator)
	{
		BladeTargetCompEnabled.Clear(Instigator);
		if(!BladeTargetCompEnabled.Get())
			BladeTargetComp.Disable(this);
	}

	// BladeGrapple
	void EnableBladeGrappleComp(FInstigator Instigator)
	{
		BladeGrappleCompEnabled.Apply(true, Instigator);
		BladeGrappleComp.Enable(this);
	}

	void ClearBladeGrappleComp(FInstigator Instigator)
	{
		BladeGrappleCompEnabled.Clear(Instigator);
		if(!BladeGrappleCompEnabled.Get())
			BladeGrappleComp.Disable(this);
	}

	// WhipTarget
	void EnableWhipTargetComp(FInstigator Instigator)
	{
		WhipTargetCompEnabled.Apply(true, Instigator);
		WhipTargetComp.Enable(this);
	}

	void ClearWhipTargetComp(FInstigator Instigator)
	{
		WhipTargetCompEnabled.Clear(Instigator);
		if(!WhipTargetCompEnabled.Get())
			WhipTargetComp.Disable(this);
	}
}