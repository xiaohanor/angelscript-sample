class ADesertGrappleFishDiveVolume : AVolume
{
	default BrushColor = FLinearColor(0.18, 0.00, 1.00);
	default BrushComponent.LineThickness = 10;
	default RootComponent.Mobility = EComponentMobility::Movable;
	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		auto GrappleFish = Cast<ADesertGrappleFish>(OtherActor);
		if (GrappleFish == nullptr)
			return;

		GrappleFish.AddDiveInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		auto GrappleFish = Cast<ADesertGrappleFish>(OtherActor);
		if (GrappleFish == nullptr)
			return;

		GrappleFish.ClearDiveInstigator(this);
	}
};