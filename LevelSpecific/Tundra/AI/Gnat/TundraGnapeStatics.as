namespace Gnape
{
	FVector GetImpactImpulse(FVector IncomingImpulse, float MaxRedirection, float ImpulseHeight)
	{
		float RedirectYaw = Math::RandRange(-1.0, 1.0) * MaxRedirection;
		FVector Base = IncomingImpulse;
		Base.Z = 0.0;
		FVector Impulse = IncomingImpulse.RotateAngleAxis(RedirectYaw, FVector::UpVector);
		Impulse += FVector::UpVector * ImpulseHeight;
		return Impulse;
	}
}
