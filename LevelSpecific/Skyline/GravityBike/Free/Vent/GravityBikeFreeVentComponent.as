class UGravityBikeFreeVentComponent : UActorComponent
{
	TInstigated<ASplineActor> InstigatedSpline;

	bool bIsActive = false;

	bool HasSpline() const
	{
		return InstigatedSpline.Get() != nullptr;
	}
};

namespace GravityBikeFree::Vent
{
	UFUNCTION(BlueprintCallable, Category = "GravityBikeFree|Vent")
	void ApplyGravityBikeFreeVentMovement(AGravityBikeFree GravityBike, ASplineActor Spline, FInstigator Instigator)
	{
		if(GravityBike == nullptr)
			return;

		auto VentComp = UGravityBikeFreeVentComponent::Get(GravityBike);
		if(VentComp == nullptr)
			return;

		VentComp.InstigatedSpline.Apply(Spline, Instigator);
	}

	UFUNCTION(BlueprintCallable, Category = "GravityBikeFree|Vent")
	void ClearGravityBikeFreeVentMovement(AGravityBikeFree GravityBike, FInstigator Instigator)
	{
		if(GravityBike == nullptr)
			return;

		auto VentComp = UGravityBikeFreeVentComponent::Get(GravityBike);
		if(VentComp == nullptr)
			return;

		VentComp.InstigatedSpline.Clear(Instigator);
	}
}