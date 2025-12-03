class UDragonSpinnerResponseComponent : UActorComponent
{
	private ADragonSpinner DragonSpinner;

	void InitiateComponent(ADragonSpinner Totem)
	{
		DragonSpinner = Totem;
	}

	float GetSpinForce()
	{
		return DragonSpinner.GetSpinForce();
	}
}