UCLASS(Abstract)
class USanctuaryBossHydraAttackData : UObject
{
	// Which attack type we want to perform.
	ESanctuaryBossHydraAttackType AttackType = ESanctuaryBossHydraAttackType::None;

	// Which hydra head is requested to perform this attack, max value means any. 
	ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX;

	// Target component, should be set if the attack should track it's target.
	USceneComponent TargetComponent = nullptr;

	// How long we want the telegraphing to be active for, value below zero uses settings default.
	float TelegraphDuration = -1.0;

	// How long we want to remain in the recover (post-attack) state before returning, value below zero uses settings default.
	float RecoverDuration = -1.0;

	FVector GetWorldLocation() const property
	{
		return FVector::ZeroVector;
	}
	
	bool IsValid() const
	{
		if (AttackType == ESanctuaryBossHydraAttackType::None)
			return false;

		return true;
	}
}

class USanctuaryBossHydraPointAttackData : USanctuaryBossHydraAttackData
{
	// Location in relative space if target component is set, otherwise world space.
	FVector Location = FVector::ZeroVector;

	// Used to determine location and rotation of the head during telegraphing.
	USceneComponent TelegraphComponent = nullptr;

	FVector GetWorldLocation() const property override
	{
		if (TargetComponent != nullptr)
		{
			return TargetComponent
				.WorldTransform
				.TransformPosition(Location);
		}

		return Location;
	}
}

class USanctuaryBossHydraSweepAttackData : USanctuaryBossHydraAttackData
{
	// Head will move along the evaluated location of this spline over the attack duration.
	FHazeRuntimeSpline HeadSpline;

	// Head will point towards the evaluated location of this spline over the attack duration.
	FHazeRuntimeSpline TargetSpline;

	// Time it should take to sweep the head along the spline, -1.0 means settings default.
	float SweepDuration = -1.0;

	// Whether the attack should completely ignore height, meaning you can't dodge it vertically.
	bool bInfiniteHeight = false;

	FVector GetWorldLocation() const property override
	{
		if (HeadSpline.Points.Num() == 0)
		{
			devError("Invalid head spline, unable to evaluate attack world location.");
			return FVector::ZeroVector;
		}

		if (HeadSpline.Points.Num() == 1)
			return HeadSpline.Points[0];

		return HeadSpline.GetLocation(0.5);
	}

	bool IsValid() const override
	{
		if (AttackType != ESanctuaryBossHydraAttackType::FireBreath)
		{
			// Require the splines to be set up if we're performing a sweeping attack
			//  one point is valid, just means it's static
			if (HeadSpline.Points.Num() == 0)
				return false;
			if (TargetSpline.Points.Num() == 0)
				return false;
		}

		return Super::IsValid();
	}
}