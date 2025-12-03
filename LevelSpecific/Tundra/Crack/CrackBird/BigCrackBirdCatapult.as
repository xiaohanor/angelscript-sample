class ABigCrackBirdCatapult : ASnowMonkeyCatapult
{
	default FauxAxisRotator.ConstrainBounce = 0.0;

	UPROPERTY(DefaultComponent, Attach=Collision)
	UFauxPhysicsWeightComponent AdditionalFauxWeight;
	default AdditionalFauxWeight.MassScale = 0.2;

	UPROPERTY(EditAnywhere)
	ABigCrackBirdNest Nest;

	void OnBirdAttach()
	{
		FauxWeight.RemoveDisabler(this);
		AdditionalFauxWeight.AddDisabler(this);
		bApplyForces = true;
		bApplyImpulses = true;
		bJustSlammed = false;
	}

	void OnBirdDetach()
	{
		FauxWeight.AddDisabler(this);
		AdditionalFauxWeight.RemoveDisabler(this);
		bApplyForces = false;
		bApplyImpulses = false;
	}
}