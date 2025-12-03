class ASpotSoundPlaneLookAtVolume : AVolume
{
	default BrushComponent.bGenerateOverlapEvents = false;
	default BrushComponent.CollisionProfileName = n"AudioCollider";
	default Shape::SetVolumeBrushColor(this, FLinearColor::Green);
	default BrushComponent.LineThickness = 6.0;

	UPROPERTY(DefaultComponent, NotVisible)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<bool> TrackingPlayers;
	default TrackingPlayers[0] = true;
	default TrackingPlayers[1] = true;

	UPROPERTY(EditInstanceOnly)
	float PositionInterpolationSpeed = 12000;

	UPROPERTY(EditInstanceOnly)
	bool bMoveToClosestLookAtOnEnd = false;

	UPROPERTY(EditInstanceOnly, Transient)
	bool bDebugLookAt = false;

	// If the player isn't looking at the mesh, we project the position on the players view forward. What's the MAX distance from mesh allowed?
	// I.e spread or attenuation from the mesh. This only affects the positioning of the emitter.
	UPROPERTY(EditInstanceOnly)
	float LookAtSpread = 2000;

	UPROPERTY(EditInstanceOnly)
	float LookAtInterpolationMaxDistance = 0;

	UPROPERTY(EditInstanceOnly)
	float LookAtInterpolationMinDistance = 0;

	private TPerPlayer<FVector> TrackedPlayerEmitterPositions;

	const float ATTENATION_PADDING_RANGE = 1000.0;

	UPROPERTY(DefaultComponent)
	USpotSoundComponent SpotSoundComp;
	default SpotSoundComp.Mode = EHazeSpotSoundMode::Basic;

	private TArray<FAkSoundPosition> PlayerLookAtPositions;
	default PlayerLookAtPositions.SetNum(2);

	private float CachedClosestPlayerFocusPointDistance = BIG_NUMBER;

	const TArray<FAkSoundPosition>& GetLookAtPositions() const property
	{
		return PlayerLookAtPositions;
	}

	const float GetDistanceToClosestPlayerFocusPoint() const property
	{
		return CachedClosestPlayerFocusPointDistance;
	}	

	float GetAttenuationRange() const property
	{
		return SpotSoundComp.Settings.AttenuationScale;	
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{			
		DisableComp.AutoDisableRange = AttenuationRange + ATTENATION_PADDING_RANGE + LookAtInterpolationMaxDistance + BrushComponent.BoundsRadius;		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float ClosestPlayerFocusPointDistance = BIG_NUMBER;
		float ClosestPlayerDistance = BIG_NUMBER;

		for(auto Player : Game::GetPlayers())
		{
			if(!TrackingPlayers[Player])
				continue;

			const FVector PlayerFocusLocation = Audio::GetEarsLocation(Player);

			const FVector PlayerViewForward = Player.PlayerListener.GetForwardVector();
			const FVector LookAtEnd = PlayerFocusLocation + (PlayerViewForward * (AttenuationRange + ATTENATION_PADDING_RANGE));

			FHazeTraceSettings Trace = Trace::InitAgainstComponent(BrushComponent);		
			auto Result = Trace.QueryTraceComponent(PlayerFocusLocation, LookAtEnd);
			FVector LookAtLocation  = Result.bBlockingHit ? Result.Location : Result.TraceEnd;	

			if(!Result.bBlockingHit && bMoveToClosestLookAtOnEnd)
			{	
				BrushComponent.GetClosestPointOnCollision(Result.TraceEnd, LookAtLocation);
			}			
	
			// Get the closest look at position on the bounds box, used for outside-of-bounds attenuation		
			FBox BoundsBox = BrushComponent.GetBounds().Box;
			auto OutsideLookAtPosition = BoundsBox.GetClosestPointTo(PlayerFocusLocation);	
			const bool bPlayerIsInside = BoundsBox.IsInside(PlayerFocusLocation);
			const bool bOtherPlayerIsInside = BoundsBox.IsInside(Audio::GetEarsLocation(Player.OtherPlayer));

			float ColliderDistToPlayer = OutsideLookAtPosition.Distance(PlayerFocusLocation);			

			float PlayerEmitterPositionInterpAlpha = 0.0;	
			if(LookAtInterpolationMaxDistance > 0)
			{
				PlayerEmitterPositionInterpAlpha = Math::Saturate(Math::Max(0, ColliderDistToPlayer - LookAtInterpolationMinDistance) / LookAtInterpolationMaxDistance);
				#if TEST
				if (bDebugLookAt || AudioDebug::IsEnabled(EDebugAudioViewportVisualization::Spots))
					PrintToScreenScaled("PlayerEmitterPositionInterpAlpha: " + PlayerEmitterPositionInterpAlpha, 0.f);
				#endif
			}	

			// Project the position towards where the player is looking but clamp it by the spread value.
			auto TargetDirection = (LookAtEnd - PlayerFocusLocation).GetSafeNormal();
			
			auto ProjectedPosition = Math::ProjectPositionOnInfiniteLine(PlayerFocusLocation, TargetDirection, LookAtLocation);	
			auto ToOutsideColliderLocation = (OutsideLookAtPosition - PlayerFocusLocation).GetSafeNormal();			
			
			ProjectedPosition = LookAtLocation.MoveTowards(ProjectedPosition, LookAtSpread);		
			LookAtLocation = ProjectedPosition;	

			FVector PlayerEmitterPosition;

			if(!BoundsBox.IsInside(LookAtLocation))
			{
				LookAtLocation = BoundsBox.GetClosestPointTo(LookAtLocation);
				LookAtLocation = Math::ProjectPositionOnInfiniteLine(PlayerFocusLocation, TargetDirection, LookAtLocation);	
			}				
			
			PlayerEmitterPosition = Math::Lerp(LookAtLocation, OutsideLookAtPosition, PlayerEmitterPositionInterpAlpha);		

			// TODO: Do we want this?
			if(!bPlayerIsInside && bOtherPlayerIsInside)		
			{
				PlayerEmitterPosition = PlayerLookAtPositions[int(Player.OtherPlayer.Player)].GetPosition();
			}

			if(ColliderDistToPlayer <= ClosestPlayerDistance)
			{
				auto FocusPoint = Result.bBlockingHit ? Result.Location : Result.TraceEnd;	
				ClosestPlayerFocusPointDistance = Math::Min(ClosestPlayerFocusPointDistance, FocusPoint.Distance(PlayerFocusLocation));	
				ClosestPlayerDistance = ColliderDistToPlayer;
			}

			const FVector PreviousLocation = TrackedPlayerEmitterPositions[Player];
			if(!PreviousLocation.IsZero())
			{
				PlayerEmitterPosition = Math::VInterpConstantTo(PreviousLocation, PlayerEmitterPosition, DeltaSeconds, PositionInterpolationSpeed);
			}

			// Cache interpolated position
			TrackedPlayerEmitterPositions[Player] = PlayerEmitterPosition;

			// Extra check on dot if no players inside
			if(!bPlayerIsInside && !bOtherPlayerIsInside)
			{
				float ProjectedPositionToColliderDot = TargetDirection.DotProduct(ToOutsideColliderLocation);
				float DotAlpha = Math::GetMappedRangeValueClamped(FVector2D(-1.0, 1.0), FVector2D(0.0, 1.0), ProjectedPositionToColliderDot);
		
				FVector ProjectedInvertedLookAtLocation = PlayerFocusLocation + (ToOutsideColliderLocation * ((AttenuationRange / 2)  * PlayerEmitterPositionInterpAlpha));
				PlayerEmitterPosition = Math::Lerp(ProjectedInvertedLookAtLocation, PlayerEmitterPosition, DotAlpha);
			}
			
			PlayerLookAtPositions[int(Player.Player)].SetPosition(PlayerEmitterPosition);

			#if TEST
			if (bDebugLookAt || AudioDebug::IsEnabled(EDebugAudioViewportVisualization::Spots))
			{
				PrintToScreenScaled("Distance: "+PlayerFocusLocation.Distance(PlayerEmitterPosition));
				Debug::DrawDebugArrow(PlayerFocusLocation, LookAtEnd, bDrawInForeground = true);
				Debug::DrawDebugPoint(PlayerEmitterPosition, 25.f, FLinearColor::Yellow, bDrawInForeground = true);
				Debug::DrawDebugPoint(OutsideLookAtPosition, 25.f, FLinearColor::DPink, bDrawInForeground = true);
			}
			#endif
		}

		CachedClosestPlayerFocusPointDistance = ClosestPlayerFocusPointDistance;

		// A sounddef won't have a Emitter on the Spot
		if(SpotSoundComp.Emitter != nullptr)
		{
			SpotSoundComp.Emitter.AudioComponent.SetMultipleSoundPositions(PlayerLookAtPositions);
		}
	}
}

class USpotSoundPlaneLookAtVolumeDetailsCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = ASpotSoundPlaneLookAtVolume;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		HideCategory(n"PathTracing");
		HideCategory(n"Navigation");
		HideCategory(n"Collision");
		HideCategory(n"Debug");
		HideCategory(n"Cooking");
		HideCategory(n"Actor");
		HideCategory(n"HLOD");
		HideCategory(n"Tags");
		HideCategory(n"BrushSettings");
		HideCategory(n"EditorRendering");
		

		EditCategory(n"LookAtBrushSettings");
		AddDefaultPropertiesFromOtherCategory(n"LookAtBrushSettings", n"BrushSettings");
		
	}

}
