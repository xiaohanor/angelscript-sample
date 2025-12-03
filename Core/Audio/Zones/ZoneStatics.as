
struct FColorCoding
{
	// Default colors in editor and when disabled in runtime
 	TArray<FLinearColor> ColorsByZoneType;
	// Color when active in runtime
	TArray<FLinearColor> ColorsByActivation;
	FLinearColor HighestPriorityColor = FLinearColor::Teal;

	FColorCoding()
	{
		//EHazeAudioZoneType::Ambience
		ColorsByZoneType.Add(FLinearColor::Red);
		//EHazeAudioZoneType::Reverb
		ColorsByZoneType.Add(FLinearColor::Blue);
		//EHazeAudioZoneType::Occlusion
		ColorsByZoneType.Add(FLinearColor::Purple);
		//EHazeAudioZoneType::Portal
		ColorsByZoneType.Add(FLinearColor::Black);
		//EHazeAudioZoneType::Water
		ColorsByZoneType.Add(FLinearColor::LucBlue);


		//EHazeAudioZoneType::Ambience
		ColorsByActivation.Add(FLinearColor::Green);
		//EHazeAudioZoneType::Reverb
		ColorsByActivation.Add(FLinearColor::Green);
		//EHazeAudioZoneType::Occlusion
		ColorsByActivation.Add(FLinearColor::Green);
		//EHazeAudioZoneType::Portal
		ColorsByActivation.Add(FLinearColor::Green);
		//EHazeAudioZoneType::Water
		ColorsByActivation.Add(FLinearColor::Green);
	}

	FLinearColor GetZoneColor(AHazeAudioZone Zone) const
	{
		return ColorsByZoneType[Zone.GetZoneType()];
	}

	FLinearColor GetActiveColor(AHazeAudioZone Zone) const
	{
		return ColorsByActivation[Zone.GetZoneType()];
	}

}

namespace AudioZone
{
	void OnBeginPlay(AHazeAudioZone Zone)
	{
		switch (Zone.RtpcCurve)
		{
		case EHazeAudioAmbientZoneCurve::Linear:
			Zone.ZoneRTPCCurvePower = 1.0;
		break;
		case EHazeAudioAmbientZoneCurve::Exponential:
			Zone.ZoneRTPCCurvePower = 2.0;
		break;
		case EHazeAudioAmbientZoneCurve::Logarithmic:
			Zone.ZoneRTPCCurvePower = 0.5;
		break;
		}

		Zone.BrushComponent.SetGenerateOverlapEvents(false);
		if (Zone.IsActorTickEnabled() && Zone.ListenerOverlaps.Num() == 0)
		{
			Zone.SetActorTickEnabled(false);
		}

		Zone.bAxisFade = Zone.FadeAxes != FVector::OneVector;
	}

	AHazePlayerCharacter GetPlayerFromOverlap(const FHazeAudioZoneObjectOverlap& Overlap)
	{
		if (Overlap.Object.Listener != nullptr)
			return Cast<AHazePlayerCharacter>(Overlap.Object.Listener.Owner);

		return nullptr;
	}

	UHazeAudioEmitter GetPlayerVoEmitterFromOverlap(const FHazeAudioZoneObjectOverlap& Overlap)
	{
		auto Player = GetPlayerFromOverlap(Overlap);

		if (Player != nullptr)
		{
			return Audio::GetPlayerVoEmitter(Player);
		}

		return nullptr;
	}

	void GetVoGameAuxVolumeValues(AHazeAudioZone AudioZone, float& GameAuxVolume, float& UserAuxVolume0, UHazeAudioActorMixer& Amix)
	{
		auto AmbientZone = Cast<AAmbientZone>(AudioZone);

		if (AmbientZone != nullptr)
		{
			GameAuxVolume = AmbientZone.PlayerVoGameAuxSendVolume;
			UserAuxVolume0 = AmbientZone.PlayerVoUserAuxSendVolume0;
			Amix = AmbientZone.VoAmixForGameAuxSendVolumeOverride;
			return;
		}

		auto ReverbZone = Cast<AReverbZone>(AudioZone);

		if (ReverbZone != nullptr)
		{
			GameAuxVolume = ReverbZone.PlayerVoGameAuxSendVolume;
			UserAuxVolume0 = ReverbZone.PlayerVoUserAuxSendVolume0;
			Amix = ReverbZone.VoAmixForGameAuxSendVolumeOverride;
		}
	}
}


namespace AudioZone
{
	const FColorCoding ZoneColors;
	// HazeAudio.ShowZonesAttenuation
	const FConsoleVariable CVar_ShowAttenuation("HazeAudio.ShowZonesAttenuation", 1);

	const float LineThickness = 15.0;
	const float PointSize = 35.0;

	struct FSharedCorner
	{
		TArray<FVector> Directions;
		TArray<FVector> PolyNormals;
	}

	// Will be used for editor/runtime
	void DrawZone(AHazeAudioZone AmbientZone, bool bHighestPriorityZone = false, UHazeScriptComponentVisualizer Visualizer = nullptr)
	{
		float Length = AmbientZone.AttenuationLength;
		FTransform BrushTransform = AmbientZone.GetActorTransform();

		auto PortalZone = Cast<APortalZone>(AmbientZone);
		if (PortalZone != nullptr)
		{
			if (Visualizer != nullptr)
			{
				// Visualizer.DrawPoint(PortalZone.ZoneAConnection.Origin, FLinearColor::Blue, PointSize);
				Visualizer.DrawWireBox(PortalZone.Connections.Origin, PortalZone.Connections.Extents, BrushTransform.Rotation, FLinearColor::Blue, Thickness = LineThickness);
			}
			else
				Debug::DrawDebugBox(PortalZone.Connections.Origin, PortalZone.Connections.Extents, BrushTransform.GetRotation().Rotator(), FLinearColor::Blue, Thickness = LineThickness);

			// if (Visualizer != nullptr)
			// {
			// 	// Visualizer.DrawPoint(PortalZone.ZoneBConnection.Origin, FLinearColor::Yellow, PointSize);
			// 	Visualizer.DrawWireBox(PortalZone.ZoneBConnection.Origin, PortalZone.ZoneBConnection.Extents, BrushTransform.Rotation, FLinearColor::Yellow, Thickness = LineThickness);
			// }
			// else
			// 	Debug::DrawDebugBox(PortalZone.ZoneBConnection.Origin, PortalZone.ZoneBConnection.Extents, BrushTransform.GetRotation().Rotator(), FLinearColor::Yellow, Thickness = LineThickness);
			return;
		}

#if EDITOR
		auto WaterZone = Cast<AWaterZone>(AmbientZone);
		if (WaterZone != nullptr)
		{
			for (auto ConnectedVolume: WaterZone.ConnectedSwimmingVolumes)
			{
				if (ConnectedVolume.IsNull() || ConnectedVolume.Get() == nullptr)
				{
					continue;
				}

				auto Volume = ConnectedVolume.Get();

				if (Visualizer != nullptr)
				{
					Visualizer.DrawArrow(BrushTransform.Location, Volume.ActorLocation,FLinearColor::Yellow, 80,  LineThickness);
					Visualizer.DrawWireBox(
						Volume.Bounds.Origin, 
						Volume.BrushComponent.GetComponentLocalBoundingBox().Extent * Volume.ActorScale3D, 
						Volume.GetActorRotation().Quaternion(), 
						FLinearColor::Yellow, LineThickness/2, true);
				}
			}
		}
#endif

		if (CVar_ShowAttenuation.GetInt() == 0
			&& Visualizer != nullptr)
		{
			return;
		}

		FLinearColor InnerColor;
		FLinearColor OuterColor;

		if (bHighestPriorityZone)
		{
			InnerColor = AudioZone::ZoneColors.HighestPriorityColor;
			OuterColor = AudioZone::ZoneColors.HighestPriorityColor;
		}
		else {
			bool bIsInside = false;
			for (const auto& ListenerOverlap :AmbientZone.ListenerOverlaps )
			{
				if (ListenerOverlap.ObjectRelevance >= 1)
				{
					bIsInside = true;
					break;
				}
			}

			InnerColor = bIsInside ?
				AudioZone::ZoneColors.GetActiveColor(AmbientZone) :
				AudioZone::ZoneColors.GetZoneColor(AmbientZone);

			OuterColor = AmbientZone.ListenerOverlaps.Num() > 0 ?
				AudioZone::ZoneColors.GetActiveColor(AmbientZone) :
				AudioZone::ZoneColors.GetZoneColor(AmbientZone);
		}

		if (Visualizer == nullptr)
		{
			bool bEarlyOut = true;
			float Radius = (AmbientZone.BrushComponent.BoundsRadius + Length) * 2;
			Radius *= Radius;

			for	(AHazePlayerCharacter Player : Game::Players)
			{
				if (Player.GetActorLocation().DistSquared(BrushTransform.Location) > Radius)
					continue;

				bEarlyOut = false;
			}

			if (bEarlyOut)
			{
				FVector Extents = AmbientZone.BrushComponent.GetComponentLocalBoundingBox().Extent * AmbientZone.ActorScale3D + FVector(Length,Length,Length);
				if (Visualizer != nullptr)
					Visualizer.DrawWireBox(AmbientZone.BrushComponent.BoundsOrigin, Extents, BrushTransform.Rotation, OuterColor, Thickness = LineThickness);
				else
					Debug::DrawDebugBox(AmbientZone.BrushComponent.BoundsOrigin, Extents, BrushTransform.GetRotation().Rotator(), OuterColor, Thickness = LineThickness);

				Debug::DrawDebugString(BrushTransform.Location, f"{AmbientZone.Priority}", InnerColor, Scale = 1.5);
				return;
			}
		}

		Debug::DrawDebugString(BrushTransform.Location, f"P: {AmbientZone.Priority}\nR: {AmbientZone.ZoneRTPCValue}", InnerColor, Scale = 1.5);

		auto Polys = AmbientZone.GetPolys();
		if (Polys.Num() == 0)
			return;

		FTransform BrushTransformNoScale = BrushTransform;
		BrushTransformNoScale.SetScale3D(FVector(1.0));

		TMap<FVector, FVector> VertsAndNormals;
		TMap<FVector, FSharedCorner> SharedCorners;

		for (const auto& Poly : Polys)
		{
			for (const auto& Vert : Poly.Vertices)
			{
				VertsAndNormals.FindOrAdd(Vert) += Poly.Normal;
			}
		}

		FVector Extents = AmbientZone.BrushComponent.GetComponentLocalBoundingBox().Extent * AmbientZone.ActorScale3D + FVector(Length,Length,Length);
		if (Visualizer != nullptr)
			Visualizer.DrawWireBox(AmbientZone.BrushComponent.BoundsOrigin, Extents, BrushTransform.Rotation, Thickness = LineThickness);
		else
			Debug::DrawDebugBox(AmbientZone.BrushComponent.BoundsOrigin, Extents, BrushTransform.GetRotation().Rotator(), Thickness = LineThickness);

		for (const auto& Poly : Polys)
		{
			if (Poly.Vertices.Num() == 4)
			{
				auto PlaneColor = OuterColor;
				PlaneColor.A = 0.4;

				auto PolyNormal = BrushTransformNoScale.TransformVector(Poly.Normal * AmbientZone.FadeAxes);
				auto Origin = AmbientZone.BrushComponent.BoundsOrigin + PolyNormal * Length;
				TArray<FVector> Verts;
				Verts.SetNum(4);
				Verts[0] = Origin + BrushTransform.TransformVector(Poly.Vertices[0]);
				Verts[1] = Origin + BrushTransform.TransformVector(Poly.Vertices[1]);
				Verts[2] = Origin + BrushTransform.TransformVector(Poly.Vertices[2]);
				Verts[3] = Origin + BrushTransform.TransformVector(Poly.Vertices[3]);

				TArray<int32> Indices;
				Indices.SetNum(6);
				Indices[0] = 0; Indices[1] = 3; Indices[2] = 1;
				Indices[3] = 1; Indices[4] = 2; Indices[5] = 3;

				Debug::DrawDebugMesh(Verts, Indices, PlaneColor);
			}

			for (int32 i = 0; i < Poly.Vertices.Num(); ++i)
			{
				int32 j = i + 1;
				if (j >= Poly.Vertices.Num())
				{
					j = 0;
				}

				FVector Vert = Poly.Vertices[i];
				FVector OtherVert = Poly.Vertices[j];

				FVector CombinedNormal = VertsAndNormals[Vert];
				FVector PolyNormal = Poly.Normal;

				SharedCorners.FindOrAdd(CombinedNormal).Directions.Add((OtherVert - Vert).GetSafeNormal());
				SharedCorners.FindOrAdd(CombinedNormal).PolyNormals.Add(PolyNormal);

				Vert = BrushTransform.TransformPosition(Vert);
				OtherVert = BrushTransform.TransformPosition(OtherVert);

				// Draw the inner zone box first.
				if (Visualizer == nullptr)
					Debug::DrawDebugLine(Vert, OtherVert, InnerColor, LineThickness);

				// Remove those axes we don't care about
				PolyNormal *= AmbientZone.FadeAxes;
				PolyNormal = BrushTransformNoScale.TransformVector(PolyNormal);

				FVector PolyVert = Vert + PolyNormal * Length;
				FVector OtherPolyVert = OtherVert + PolyNormal * Length;

				FSharedCorner SharedCorner;
				if (SharedCorners.Find(CombinedNormal, SharedCorner) && SharedCorner.Directions.Num() > 2)
				{
					for (int index = 0; index < SharedCorner.Directions.Num(); ++index)
					{
						int32 j_index = index + 1;
						if (j_index >= SharedCorner.Directions.Num())
						{
							j_index = 0;
						}

						const auto& DirectionA = SharedCorner.PolyNormals[index];
						const auto& DirectionB = SharedCorner.PolyNormals[j_index];
						auto NewDirection = DirectionA + DirectionB;

						float Degrees = DirectionA.GetAngleDegreesTo(DirectionB);
						auto NewNormal = DirectionA.CrossProduct(DirectionB);
						NewNormal.Normalize();

						if (NewDirection * AmbientZone.FadeAxes != NewDirection)
						{
							continue;
						}

						NewDirection = BrushTransformNoScale.TransformVector(NewDirection);
						NewNormal = BrushTransformNoScale.TransformVector(NewNormal);

						if (Visualizer != nullptr)
						{
							Visualizer.DrawArc(Vert, Degrees, Length, NewDirection, OuterColor, LineThickness, NewNormal, bDrawSides = false);
						}
						else
							Debug::DrawDebugArc(Degrees, Vert, Length, NewDirection, OuterColor, LineThickness, NewNormal, bDrawSides = false);
					}
				}

				if (Visualizer != nullptr)
					Visualizer.DrawLine(PolyVert, OtherPolyVert, OuterColor, LineThickness);
				else
					Debug::DrawDebugLine(PolyVert, OtherPolyVert, OuterColor, LineThickness);
			}
		}
	}

}
