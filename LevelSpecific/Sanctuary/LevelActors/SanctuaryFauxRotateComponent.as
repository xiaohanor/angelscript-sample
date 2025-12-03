class USanctuaryFauxRotateComponent : UFauxPhysicsAxisRotateComponent
{
	void ApplyForce(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingForces += LinearToAngular(Origin, Force) * ForceScalar;
		Wake();
	}

	void ApplyImpulse(FVector Origin, FVector Force) override
	{
		if (!IsEnabled())
			return;

		PendingForces += LinearToAngular(Origin, Force) * ForceScalar;
		Wake();
	}

	float LinearToAngular(FVector Origin, FVector Force)
	{
		if (TorqueBounds == 0.0)
		{
			devError("Converting linear to angular forces on an object with 0 bound radius.\nI'm sorry you have to see this but can you poke Emil? :(");
			return 0.0;
		}

		FVector Offset = Origin - WorldLocation;

		FVector Angular = Offset.CrossProduct(Force) / (TorqueBounds * TorqueBounds);

//		Debug::DrawDebugLine(Origin, Origin + Angular.SafeNormal * 100.0, FLinearColor::Red, 10.0, 0.0);
//		Debug::DrawDebugLine(Origin, Origin + WorldRotationAxis * 100.0, FLinearColor::Blue, 10.0, 0.0);

		FVector ProjectedAngular = Angular.ProjectOnToNormal(WorldRotationAxis);
//		Debug::DrawDebugLine(Origin, Origin + ProjectedAngular * 100.0, FLinearColor::Yellow, 10.0, 0.0);

		return ProjectedAngular.DotProduct(WorldRotationAxis);
	}
}