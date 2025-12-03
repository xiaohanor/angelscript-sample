
class UIslandTurretronTrackTargetBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	FVector InitialUpDir;
	AAIIslandTurretron Turret;

	UIslandTurretronSettings Settings;

	bool bShouldPredict = false;
	bool bHasSetCurrentTargetLoc = false;
	FVector CurrentTargetLoc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		InitialUpDir = Owner.ActorUpVector;

		Settings = UIslandTurretronSettings::GetSettings(Owner);
		Turret = Cast<AAIIslandTurretron>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasGeometryVisibleTarget())
			return false;
		if (!Settings.bShouldTrackTarget)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasGeometryVisibleTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
			TargetDirectly(DeltaTime);
	}

	private void TargetDirectly(float DeltaTime)
	{
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	

		FVector Dir = (TargetLoc - Owner.ActorCenterLocation).GetSafeNormal();
		
		// Ease rotation for holder
		FVector CurrentDir = Turret.Mesh_Holder.WorldRotation.Vector();
		const float RotationSpeed = 10;
		float Delta = RotationSpeed * DeltaTime;
		FVector NewDir = CurrentDir.SlerpTowards(Dir, Delta);

		Turret.Mesh_Holder.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, NewDir));
		CurrentDir = Turret.Mesh_Holder.WorldRotation.Vector().GetSafeNormal(); // gets constrained before calculating vertical angle.
		
		// Ease rotation for gun
		FVector CurrentGunDir = Turret.Mesh_Turret.WorldRotation.Vector();
		const float GunRotationSpeed = 10;
        float HolderDelta = GunRotationSpeed * DeltaTime;
        CurrentGunDir = CurrentGunDir.SlerpTowards(Dir, HolderDelta);
        
        // Calculate the angle in radians between CurrentGunDir and CurrentDir
        float VerticalAngle = Math::Acos(CurrentGunDir.DotProduct(CurrentDir));
        // Convert to degrees
        float VerticalAngleDegrees = Math::RadiansToDegrees(VerticalAngle);
        // Clamp the angle to desired maximum pitch
        const float MaxPitchAngle = 60.0;
        VerticalAngleDegrees = Math::Min(VerticalAngleDegrees, MaxPitchAngle);
        // Convert back to radians
        VerticalAngle = Math::DegreesToRadians(VerticalAngleDegrees);
		
        FVector WorldUp = FVector::UpVector;
		float Sign = Math::Sign(CurrentGunDir.DotProduct(WorldUp));
        CurrentGunDir = CurrentDir.RotateAngleAxis(Sign * VerticalAngleDegrees, CurrentDir.CrossProduct(WorldUp));
		// Draw 
        //Debug::DrawDebugLine(Turret.ActorCenterLocation, Turret.ActorCenterLocation + WorldUp.CrossProduct(CurrentDir) * 1000);
        //Debug::DrawDebugLine(Turret.ActorCenterLocation, Turret.ActorCenterLocation + WorldUp.CrossProduct(CurrentDir) * 1000);
        //Debug::DrawDebugLine(Turret.ActorCenterLocation, Turret.ActorCenterLocation + CurrentGunDir * 1000, FLinearColor::Red, 3.0, 0.0);
        		        
        FVector RightVector = Turret.Mesh_Turret.GetRightVector();
        Turret.Mesh_Turret.SetWorldRotation(FRotator::MakeFromYX(RightVector, CurrentGunDir));
	}

	private void TargetPredictively(float DeltaTime)
	{
			FVector TargetLoc = TargetComp.Target.ActorCenterLocation;	
			if (!bHasSetCurrentTargetLoc)
				CurrentTargetLoc = TargetLoc;
			bHasSetCurrentTargetLoc = true;

			// Predict movement
			FVector TargetVelocity = Cast<AHazePlayerCharacter>(TargetComp.Target).GetRawLastFrameTranslationVelocity();
			TargetVelocity.Z = 0; // Prevents overcompensating while player is jumping
			float Distance = TargetLoc.Distance(Owner.ActorCenterLocation);
			TargetLoc += TargetVelocity.GetSafeNormal() * (Distance * (TargetVelocity.Size() / Settings.LaunchSpeed));
			
			const float LerpSpeed = 600.0;
			CurrentTargetLoc += (TargetLoc - CurrentTargetLoc).GetSafeNormal() * DeltaTime * LerpSpeed;
#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(CurrentTargetLoc, 10, LineColor = FLinearColor::Green);		
			Debug::DrawDebugSphere(TargetLoc, 10, LineColor = FLinearColor::Red);
		}			
#endif
			
			FVector Dir = (CurrentTargetLoc - Owner.ActorCenterLocation).GetSafeNormal();
			Turret.Mesh_Holder.SetWorldRotation(FRotator::MakeFromZX(InitialUpDir, Dir));

			FVector RightVector = Turret.Mesh_Holder.GetRightVector();
			Turret.Mesh_Turret.SetWorldRotation(FRotator::MakeFromYX(RightVector, Dir));
	}
}