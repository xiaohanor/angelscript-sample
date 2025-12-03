event void FSanctuaryLightOrbPulseSignature();

class USanctuaryLightOrbPulseResponseComponent : USceneComponent
{
	FSanctuaryLightOrbPulseSignature OnPulseImpact;
	FSanctuaryLightOrbPulseSignature OnPulseEnd;


	UPROPERTY(EditAnywhere)
	float ForceMultiplier = 1;

	bool bIsAddingImpulse;
	FVector ImpulseForce;
	FVector Velocity;

	float TimeAtImpulse;


	void AddImpulse(FVector SourceLocation, float Force)
	{
		if(bIsAddingImpulse)
			return;
		
		OnPulseImpact.Broadcast();

		FVector Direction = Owner.ActorLocation - SourceLocation;
		
		ImpulseForce = Direction * Force * ForceMultiplier;


		Velocity = ImpulseForce;
		// TimeAtImpulse = Time::GameTimeSeconds;

		// bIsAddingImpulse = true;

		// ApplyFauxImpulseToActor(Owner, Velocity);
		FauxPhysics::ApplyFauxImpulseToActorAt(Owner, WorldLocation, ImpulseForce);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if(!bIsAddingImpulse)
		// 	return;

		// Owner.AddActorWorldOffset(Velocity * DeltaSeconds);

		// float Alpha = Math::GetMappedRangeValueClamped(FVector2D(TimeAtImpulse, TimeAtImpulse + 0.5), FVector2D(0, 1), Time::GameTimeSeconds);
		// Velocity = Math::Lerp(ImpulseForce, FVector(0), Alpha);


		// if(Alpha >= 1)
		// {
		// 	bIsAddingImpulse = false;
		// 	OnPulseEnd.Broadcast();
		// }

	}



};