class UCameraUserDebugLoggerCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastDemotable;
	default TickGroupOrder = 1000;

	UCameraUserComponent User;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(User == nullptr)
			return false;
		
		if(User.ActiveCamera == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(User == nullptr)
			return true;

		if(User.ActiveCamera == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		#if !RELEASE
		auto TemporalLog = User.GetCameraTemporalLog();

		auto UserSettings = UCameraUserSettings::GetSettings(Owner);

		// Camera
		auto ActiveCamera = User.ActiveCamera;
		{
			TemporalLog.Value(f"{CameraDebug::CategoryCamera};Camera Type:", ActiveCamera.Class);
			TemporalLog.Value(f"{CameraDebug::CategoryCamera};Camera Component:", ActiveCamera);
			
			#if EDITOR
			TemporalLog.Value(f"{CameraDebug::CategoryCamera};Camera Owner:", ActiveCamera.Owner.GetName() + " | (" + ActiveCamera.Owner.GetActorLabel() + ")");
			#else
			TemporalLog.Value(f"{CameraDebug::CategoryCamera};Camera Owner:", ActiveCamera.Owner.GetName());
			#endif

			const TArray<FInstigator> ActivationInstigators = User.GetDebugInstigatorsForCamera(ActiveCamera);
			for(int i = 0; i < ActivationInstigators.Num(); i++)
				TemporalLog.Value(f"{CameraDebug::CategoryCamera};Activation Instigators;Instigator {i+1}:", ActivationInstigators[i]);
		}

		const float DebugArrowSize = 1000;
		const float DebugSphereSize = 100;
		const float DebugPointSize = 5;

		// Transforms
		auto CameraTransform = User.GetActiveCameraTransform();
		auto UnModifiedView = User.GetCameraView(false, bGetOtherPlayersViewIfNoScreen = false);
		auto ViewModified = User.GetCameraView(bGetOtherPlayersViewIfNoScreen = false);
		auto PreviousView = User.GetPreviousCameraView(false, bGetOtherPlayersViewIfNoScreen = false);
		
		{
			// View
			{
				TemporalLog.Value(f"{CameraDebug::CategoryView};FOV:", UnModifiedView.FOV);
				TemporalLog.Value(f"{CameraDebug::CategoryView};AspectRatio:", UnModifiedView.AspectRatio);
				TemporalLog.Value(f"{CameraDebug::CategoryView};View Size:", User.GetDebugCameraViewSizeType());
				TemporalLog.Camera(f"{CameraDebug::CategoryView};Camera", ViewModified.Location, ViewModified.Rotation, ViewModified.FOV);

				TemporalLog.Point(f"{CameraDebug::CategoryView};Location;Position:", ViewModified.Location, DebugPointSize, Color = FLinearColor::White);
				TemporalLog.Sphere(f"{CameraDebug::CategoryView};Location;BigPosition:", ViewModified.Location, DebugSphereSize, Color = FLinearColor::White);
				//TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Location;Value:", ViewModified.Location);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Location;Modification:", ViewModified.Location - UnModifiedView.Location);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Location;Velocity:", UnModifiedView.ViewVelocity);

				TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Rotation;Value:", ViewModified.Rotation);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Rotation;Modification:", ViewModified.Rotation - UnModifiedView.Rotation);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Rotation;Velocity:", UnModifiedView.ViewAngularVelocity);
				TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryView};Rotation;Direction:", ViewModified.Location, ViewModified.Rotation.ForwardVector * DebugArrowSize, Color = FLinearColor::White);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryView};Rotation;DeltaValue:", (UnModifiedView.Rotation - PreviousView.Rotation).GetNormalized());	
			}

			// Camera
			{

				// This is where the camera actually is. The view might be blending
				//TemporalLog.CompactValue(f"{CameraDebug::CategoryCameraTransform};Location;Value:", CameraTransform.ViewLocation);
				TemporalLog.Point(f"{CameraDebug::CategoryCameraTransform};Location;Position:", CameraTransform.ViewLocation, DebugPointSize, Color = FLinearColor::Gray);
				TemporalLog.Sphere(f"{CameraDebug::CategoryCameraTransform};Location;BigPosition:", CameraTransform.ViewLocation, DebugSphereSize, Color = FLinearColor::Gray);
				TemporalLog.Sphere(f"{CameraDebug::CategoryCameraTransform};Location;Actor:", User.ActiveCamera.WorldLocation, DebugSphereSize, Color = FLinearColor(0.27, 0.27, 0.27));
				
				TemporalLog.CompactValue(f"{CameraDebug::CategoryCameraTransform};Rotation;Value:", CameraTransform.ViewRotation);
				TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryCameraTransform};Rotation;Direction:", CameraTransform.ViewLocation, CameraTransform.ViewRotation.ForwardVector * DebugArrowSize, Color = FLinearColor::Gray);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryCameraTransform};Rotation;Actor:", User.ActiveCamera.WorldRotation);
			}

			// User
			{
				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};UserLocation;Value:", CameraTransform.UserLocation);
				TemporalLog.Sphere(f"{CameraDebug::CategoryUser};UserLocation;Position:", CameraTransform.UserLocation, DebugSphereSize, Color = FLinearColor(0.27, 0.27, 0.27));	

				FVector LocalPivotOffset = User.Owner.ActorRotation.UnrotateVector(CameraTransform.PivotLocation - User.Owner.ActorLocation);
				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};Pivot;Value:", CameraTransform.PivotLocation);
				TemporalLog.Sphere(f"{CameraDebug::CategoryUser};Pivot;Position:", CameraTransform.PivotLocation, DebugSphereSize, Color = FLinearColor::Yellow);	
				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};Pivot;Offset:", LocalPivotOffset);
				TemporalLog.Value(f"{CameraDebug::CategoryUser};Pivot;Distance:", CameraTransform.PivotLocation.Distance(CameraTransform.ViewLocation));
				TemporalLog.Value(f"{CameraDebug::CategoryUser};Pivot;Height Diff:", (User.Owner.ActorLocation - CameraTransform.PivotLocation).ProjectOnToNormal(CameraTransform.YawAxis).Size());
				TemporalLog.Value(f"{CameraDebug::CategoryUser};Pivot;Height Pitch Diff:", (CameraTransform.ViewLocation - CameraTransform.PivotLocation).ProjectOnToNormal(CameraTransform.YawAxis).Size());	

				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};ControlRotation;Value:", CameraTransform.ControlRotation);
				TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUser};ControlRotation;Direction", CameraTransform.ViewLocation, CameraTransform.ControlRotation.ForwardVector * DebugArrowSize, Color = FLinearColor::Blue);

				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};DesiredRotation;Value:", CameraTransform.WorldDesiredRotation);
				TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUser};DesiredRotation;Direction", CameraTransform.ViewLocation, CameraTransform.WorldDesiredRotation.ForwardVector * DebugArrowSize, Color = FLinearColor::LucBlue);

				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};Local Desired Delta Rotation;Value:", CameraTransform.LocalDesiredRotationDeltaChange);

				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};Follow Movement Delta Rotation;Value:", CameraTransform.UserMovementRotationDelta);

				TemporalLog.CompactValue(f"{CameraDebug::CategoryUser};YawAxis;Value:", CameraTransform.YawAxis);
				TemporalLog.DirectionalArrow(f"{CameraDebug::CategoryUser};YawAxis;Direction", CameraTransform.PivotLocation, CameraTransform.YawAxis * DebugArrowSize, Color = FLinearColor::DPink);

				//TemporalLog.Arrow(f"{CameraDebug::CategoryShapes};BaseRotation:Direction", CameraTransform.ViewLocation, CameraTransform.ViewLocation + (CameraTransform.BaseRotation.ForwardVector * DebugArrowSize), Size = 5, Color = FLinearColor::Teal);
			}
		}
		
		// Settings
		auto Settings = User.CameraSettings;
		if(Settings != nullptr)
		{		
			TemporalLog.Value(f"{CameraDebug::CategorySettings};FOV:", Settings.FOV.Value);
			TemporalLog.Value(f"{CameraDebug::CategorySettings};IdealDistance:", Settings.IdealDistance.Value);
			TemporalLog.Value(f"{CameraDebug::CategorySettings};MinDistance:", Settings.MinDistance.Value);
			
			TemporalLog.Value(f"{CameraDebug::CategorySettings};OffsetFactor:", Settings.CameraOffsetBlockedFactor.Value);
			TemporalLog.CompactValue(f"{CameraDebug::CategorySettings};PivotOffset:", Settings.PivotOffset.Value);
			TemporalLog.CompactValue(f"{CameraDebug::CategorySettings};WorldPivotOffset:", Settings.WorldPivotOffset.Value);
			TemporalLog.CompactValue(f"{CameraDebug::CategorySettings};CameraOffset:", Settings.CameraOffset.Value);
			TemporalLog.CompactValue(f"{CameraDebug::CategorySettings};CameraOffsetOwnerSpace:", Settings.CameraOffsetOwnerSpace.Value);

			TemporalLog.Value(f"{CameraDebug::CategorySettings};PivotOffsetHeight:", Settings.PivotOffset.Value.Z + Settings.WorldPivotOffset.Value.Z);
			TemporalLog.Value(f"{CameraDebug::CategorySettings};CameraOffsetHeight:", Settings.CameraOffset.Value.Z +  Settings.CameraOffsetOwnerSpace.Value.Z);

			TemporalLog.CompactValue(f"{CameraDebug::CategorySettings};PivotLagAccelerationDuration:", Settings.PivotLagAccelerationDuration.Value);
			TemporalLog.CompactValue(f"{CameraDebug::CategorySettings};PivotLagMax:", Settings.PivotLagMax.Value);

			// Instigators
			{
				TemporalLog.Value(f"{CameraDebug::CategoryViewInstigator};Input Delta Rotation:", User.DebugInputInstigator);	
				TemporalLog.Value(f"{CameraDebug::CategoryViewInstigator};Desired Rotation:", User.DebugDesiredRotationInstigators);
				TemporalLog.Value(f"{CameraDebug::CategoryViewInstigator};Yaw Axis:", User.DebugCameraYawAxisInstigator);	
				
				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.FOV, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "FOV", Instigators);
				}
				
				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.IdealDistance, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "IdealDistance", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.MinDistance, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "MinDistance", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.CameraOffset, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "CameraOffset", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.CameraOffsetBlockedFactor, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "CameraOffsetBlockedFactor", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.CameraOffsetOwnerSpace, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "CameraOffsetOwnerSpace", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.ChaseAssistFactor, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "ChaseAssistFactor", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.PivotLagAccelerationDuration, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "PivotLagAccelerationDuration", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.PivotLagMax, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "PivotLagMax", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.PivotLagMaxMultiplier, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "PivotLagMaxMultiplier", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.PivotOffset, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "PivotOffset", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.SensitivityFactor, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "SensitivityFactor", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.SensitivityFactorPitch, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "SensitivityFactorPitch", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.SensitivityFactorYaw, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "SensitivityFactorYaw", Instigators);
				}

				{
					TArray<FInstigator> Instigators;
					Settings.GetDebugInstigators(Settings.WorldPivotOffset, Instigators);
					CameraDebug::DrawDebugInstigators(TemporalLog, "WorldPivotOffset", Instigators);
				}

				{
					auto CameraFollowMovementData = UCameraFollowMovementFollowDataComponent::Get(Owner);
					CameraDebug::DrawDebugInstigators(TemporalLog, "CameraFollowMovement", CameraFollowMovementData.GetActivationInstigators());
				}
			}
		}

		// Modifiers
		{
			FHazeCameraModifiersDebugData ModifierDebugData;
			User.Modifier.GetDebugData(ModifierDebugData);

			// Animations
			for(int i = 0; i < ModifierDebugData.Animations.Num(); ++i)
			{
				TemporalLog.Value(f"{CameraDebug::CategoryModifiers};Animation_{i+1}:", ModifierDebugData.Animations[i]);
			}

			// Impulses
			for(int i = 0; i < ModifierDebugData.Impulses.Num(); ++i)
			{
				TemporalLog.Value(f"{CameraDebug::CategoryModifiers};Impulse_{i+1}:", ModifierDebugData.Impulses[i]);
			}

			// Shakes
			for(int i = 0; i < ModifierDebugData.Shakes.Num(); ++i)
			{
				TemporalLog.Value(f"{CameraDebug::CategoryModifiers};Shake_{i+1}:", ModifierDebugData.Shakes[i]);
			}

			// Instigators
			CameraDebug::DrawDebugInstigators(TemporalLog, "ModifierBlockers", ModifierDebugData.ModifierBlockers);
			CameraDebug::DrawDebugInstigators(TemporalLog, "ImpulseBlockers", ModifierDebugData.ImpulseBlockers);
		}

		// POI's
		if(Settings != nullptr)
		{
			FHazeCameraSettingsPropertyDebugInfo POI;
			Settings.GetDebugPointOfInterestInfo(POI);
			if(POI.AffectingValues.Num() > 0)
			{
				auto Info = POI.AffectingValues[POI.HighestAffectingValue];
				TemporalLog.Value(f"{CameraDebug::CategoryPOI};POI:", Info.Instigator);	
				TemporalLog.Value(f"{CameraDebug::CategoryPOI};Target:", Info.PropertyValue);
				TemporalLog.Value(f"{CameraDebug::CategoryPOI};Alpha:", Info.Alpha);
				TemporalLog.Value(f"{CameraDebug::CategoryPOI};Fraction:", Info.Fraction);	
			}
			else
			{
				TemporalLog.Value(f"{CameraDebug::CategoryPOI};POI:", "None");
			}	
		}

		// Clamp
		if(Settings != nullptr)
		{
			FHazeActiveCameraClampSettings Clamps;
			if(Settings.Clamps.GetClamps(Clamps))
			{
				if(Clamps.PitchUp.Value < 180)
					TemporalLog.Value(f"{CameraDebug::CategoryClamps};PitchUp:", Clamps.PitchUp.Value);

				if(Clamps.PitchDown.Value < 180)
					TemporalLog.Value(f"{CameraDebug::CategoryClamps};PitchDown:",  Clamps.PitchDown.Value);

				if(Clamps.YawLeft.Value < 180)
					TemporalLog.Value(f"{CameraDebug::CategoryClamps};YawLeft:", Clamps.YawLeft.Value);

				if(Clamps.YawRight.Value < 180)
					TemporalLog.Value(f"{CameraDebug::CategoryClamps};YawRight:", Clamps.YawRight.Value);
			}
		}

		// Keep in view
		if(Settings != nullptr && Settings.HasActiveKeepInView())
		{
			FHazeCameraActiveKeepInViewSettings KeepInView; 
			Settings.KeepInView.GetSettings(KeepInView);
			TemporalLog.Value(f"{CameraDebug::CategoryKeepInView};MinDistance: ", KeepInView.MinDistance);
			TemporalLog.Value(f"{CameraDebug::CategoryKeepInView};MaxDistance: ", KeepInView.MaxDistance);
			TemporalLog.Value(f"{CameraDebug::CategoryKeepInView};BufferDistance: ", KeepInView.BufferDistance);
			TemporalLog.CompactValue(f"{CameraDebug::CategoryKeepInView};LookOffset: ", KeepInView.LookOffset);
		}

		// Collision settings
		if(UserSettings != nullptr)
		{
			TemporalLog.Value(f"{CameraDebug::CameraCollision};Camera Collision: ", ActiveCamera.CameraCollisionParams.bUseCollision);
			TemporalLog.Value(f"{CameraDebug::CameraCollision};Camera Trace Enabled: ", UserSettings.bAllowCameraTrace);		
		}

		#endif
	}
}