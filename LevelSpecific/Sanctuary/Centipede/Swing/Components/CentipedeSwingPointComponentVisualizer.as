#if EDITOR
class UCentipedeSwingPointComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCentipedeSwingPointComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UCentipedeSwingPointComponent SwingPointComponent = Cast<UCentipedeSwingPointComponent>(Component);
		if (SwingPointComponent == nullptr)
			return;
		if (Editor::IsPlaying())
			return;

		// Draw swing on plane
		float CentipedeHeadRadius = 100;
		DrawArc(SwingPointComponent.WorldLocation, 180, Centipede::MaxPlayerDistance + CentipedeHeadRadius, FVector::DownVector, FLinearColor::Green, 3, SwingPointComponent.SwingPlaneVector, 16);

		TArray<AActor> SwingPoints = Editor::GetAllEditorWorldActorsOfClass(ACentipedeSwingPoint);
		SwingPoints.Append(Editor::GetAllEditorWorldActorsOfClass(ACentipedeSwingLandTarget));
		for (AActor TargetActor : SwingPoints)
		{
			UCentipedeSwingJumpTargetComponent SwingJumpTargetable = UCentipedeSwingJumpTargetComponent::Get(TargetActor);
			if (SwingJumpTargetable != nullptr)
			{
				if (SwingJumpTargetable.Owner == SwingPointComponent.Owner)
					continue;

				const float ValidDistance = Centipede::MaxPlayerDistance + SwingJumpTargetable.ActivationRange + SwingJumpTargetable.AdditionalVisibleRange;
				float Distance = SwingPointComponent.WorldLocation.Distance(SwingJumpTargetable.WorldLocation);
				if (Distance > ValidDistance)
					continue;

				float GravityMagnitude = 2385 * 1.5; // Blah
				if (SwingJumpTargetable.IsA(UCentipedeSwingPointComponent))
				{
					float Height = Math::Max(0.0, SwingJumpTargetable.WorldLocation.Z - SwingPointComponent.WorldLocation.Z) + Centipede::SwingJumpHeight;
					FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(SwingPointComponent.WorldLocation, SwingJumpTargetable.WorldLocation, GravityMagnitude, Height);

					DrawTrajectory(SwingPointComponent.WorldLocation, Impulse, GravityMagnitude, Distance, Height, FLinearColor::DPink);
				}
				else
				{
					UCentipedeSwingLandTargetComponent LandTargetComponent = Cast<UCentipedeSwingLandTargetComponent>(SwingJumpTargetable);
					if (LandTargetComponent != nullptr)
					{
						// Draw Mio
						float Height = Math::Max(0.0, LandTargetComponent.GetMioTargetTransform().Location.Z - SwingPointComponent.WorldLocation.Z) + Centipede::SwingJumpHeight;
						FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(SwingPointComponent.WorldLocation, LandTargetComponent.GetMioTargetTransform().Location, GravityMagnitude, Height);
						DrawTrajectory(SwingPointComponent.WorldLocation, Impulse, GravityMagnitude, Distance, Height, FLinearColor::Green);

						// Draw Zoe
						Height = Math::Max(0.0, LandTargetComponent.GetZoeTargetTransform().Location.Z - SwingPointComponent.WorldLocation.Z) + Centipede::SwingJumpHeight;
						Impulse = Trajectory::CalculateVelocityForPathWithHeight(SwingPointComponent.WorldLocation, LandTargetComponent.GetZoeTargetTransform().Location, GravityMagnitude, Height);
						DrawTrajectory(SwingPointComponent.WorldLocation, Impulse, GravityMagnitude, Distance, Height, FLinearColor::LucBlue);
					}
				}
			}
		}
	}

	void DrawTrajectory(FVector Origin, FVector Velocity, float GravityMagnitude, float Distance, float Height, FLinearColor Color)
	{
		Trajectory::FTrajectoryPoints Points = Trajectory::CalculateTrajectory(Origin, Distance + Height, Velocity, GravityMagnitude, 1.5);
		for(int i=0; i<Points.Positions.Num() - 1; ++i)
		{
			FVector Start = Points.Positions[i];
			FVector End = Points.Positions[i + 1];

			DrawDashedLine(Start, End, Color, Thickness = 3);
		}
	}
}
#endif