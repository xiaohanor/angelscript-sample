/**
* Calculate impulses to nearby players from a world position and range
* This is usually applied as delta from velocity. OBS! This is applied when the movement is performed
* @param AffectedPlayers				The player characters that will be affected by the impulse.
* @param Epicenter						Location where the impulse originates from in world space.
* @param StrengthAtEpicenter			How strong the impulse will be at the epicenter
* @param InnerRadius					Players inside this radius get the impulse at full intensity.
* @param OuterRadius					Players outside this radius will not be affected.
* @param Falloff						Exponent that describes the intensity falloff curve between InnerRadius and OuterRadius. 1.0 is linear.
*/
UFUNCTION(Meta = (AdvancedDisplay = "bDebugDraw"))
void AddMovementWorldImpulse(EHazeSelectPlayer AffectedPlayers = EHazeSelectPlayer::Both, FVector Epicenter = FVector::ZeroVector, float StrengthAtEpicenter = 2000.0,
	float InnerRadius = 200.0, float OuterRadius = 600.0, float Falloff = 1.0, FName NameOfImpulse = NAME_None, bool bDebugDraw = false)
{
	for (auto Player : Game::Players)
	{
		if (!Player.IsSelectedBy(AffectedPlayers))
			continue;
		
		float DistanceToEpicenter = Player.ActorLocation.Distance(Epicenter);
		if (DistanceToEpicenter > OuterRadius)
			continue;

		FVector DirectionToPlayer = (Player.ActorLocation - Epicenter).GetSafeNormal();
		float Intensity = 1.0;
		if (DistanceToEpicenter > InnerRadius)
		{
			float Fraction = Math::Saturate((DistanceToEpicenter - InnerRadius) / (OuterRadius - InnerRadius));
			Intensity = Math::Pow(1.0 - Fraction, Falloff);
		}
		Player.AddMovementImpulse(DirectionToPlayer * StrengthAtEpicenter * Intensity, NameOfImpulse);
	}

#if EDITOR
		if (bDebugDraw)
		{
			Debug::DrawDebugSphere(Epicenter, InnerRadius, 12, FLinearColor::Red, Duration = 3.0);
			Debug::DrawDebugSphere(Epicenter, OuterRadius, 12, FLinearColor::Green, Duration = 3.0);
		}
#endif
}