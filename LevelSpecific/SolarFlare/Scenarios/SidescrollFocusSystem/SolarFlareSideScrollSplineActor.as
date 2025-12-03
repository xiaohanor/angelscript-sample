class ASolarFlareSideScrollSplineActor : ASplineActor
{	
	UPROPERTY(EditAnywhere)
	float MinZ = -200;

	UPROPERTY(EditAnywhere)
	float MaxZ = 300.0;

	float DrawIntervals = 100.0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		int Intervals = int(Spline.SplineLength / DrawIntervals);
		FVector LastBottom = FVector(0);
		FVector LastTop = FVector(0);
		bool bFirstIteration = true;

		for (int i = 0; i < Intervals; i++)
		{
			FVector StartLoc = Spline.GetWorldLocationAtSplineDistance(DrawIntervals * i);
			FVector Bottom = StartLoc + (FVector::UpVector * MinZ);
			FVector Top = StartLoc + (FVector::UpVector * MaxZ);

			// Debug::DrawDebugLine(StartLoc, StartLoc + (FVector::UpVector * MaxZ), FLinearColor::Green, 15.0);	
			// Debug::DrawDebugLine(StartLoc, StartLoc + (FVector::UpVector * MinZ), FLinearColor::Green, 15.0);	

			if (bFirstIteration)
			{
				LastBottom = Bottom;
				LastTop = Top;
				bFirstIteration = false;
			}
			else
			{
				Debug::DrawDebugLine(LastBottom, Bottom, FLinearColor::Green, 15.0);	
				Debug::DrawDebugLine(LastTop, Top, FLinearColor::Green, 15.0);	
				LastBottom = Bottom;
				LastTop = Top;
			}
		}
	}
#endif
};