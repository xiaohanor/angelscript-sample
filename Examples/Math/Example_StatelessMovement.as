/**
 * An example for how to use a time value to make stateless movement in an actor.
 */
class AExample_StatelessMovement : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// First, get the time from the crumb trail
		// This is a value that starts at 0 and increases to infinity, just like game time (but synced)
		float Time = Time::PredictedGlobalCrumbTrailTime;

		// Wrap the time with a duration, so instead of going from 0->infinite it will
		// loop 0->3, 0->3, 0->3, etc
		float Duration = 3.0;
		float CurrentTimeInsideDuration = Math::Wrap(Time, 0.0, Duration);

		// Now we can use a 'Remap' to go from a time value to a rotation or position
		// For example, this value will go from -150 to +150, then snaps back to -150
		float WantedHeight = Math::GetMappedRangeValueClamped(
			FVector2D(0.0, Duration),
			FVector2D(-150.0, 150.0),
			CurrentTimeInsideDuration
		);

		// If we want to do a "back and forth" movement, we could first check whether it was halfway,
		// and then do two remaps:
		FVector NewLocation = ActorRelativeLocation;
		if (CurrentTimeInsideDuration < Duration * 0.5)
		{
			NewLocation.Z = Math::GetMappedRangeValueClamped(
				FVector2D(0, Duration * 0.5), // Remap the first half of the duration
				FVector2D(0, 100), // Move up to 100 units
				CurrentTimeInsideDuration
			);
		}
		else
		{
			NewLocation.Z = Math::GetMappedRangeValueClamped(
				FVector2D(Duration * 0.5, Duration), // Remap the second half of the duration
				FVector2D(100, 0), // Move back down to 0 units
				CurrentTimeInsideDuration
			);
		}

		ActorRelativeLocation = NewLocation;
	}
};