class USkylineTorOpportunityAttackCameraComponent : UHazeCameraComponent
{
	// Camera is placed on socket on boss. If animation is too compressed for this to be smooth, 
	// we'll need to extract sample points and construct a curve from these instead.

	FVector TargetRelativeLocation;
	FRotator TargetRelativeRotation;
	float TargetPivotDistance = 100.0;	
	AHazeCharacter Boss;
	FHazeAcceleratedRotator AccRotation;
	FHazeAcceleratedFloat AccPivotDistance;
	FHazeAcceleratedVector AccPivotLocation;

	UHazeCharacterSkeletalMeshComponent AttachMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetRelativeLocation = RelativeLocation;
		TargetRelativeRotation = RelativeRotation;
		Boss = Cast<AHazeCharacter>(AttachParent.Owner);
		AttachMesh = Cast<UHazeCharacterSkeletalMeshComponent>(AttachParent);
		check(AttachMesh.DoesSocketExist(AttachSocketName));
	}

	void StartAttackSequence(AHazePlayerCharacter Player)
	{
		AccRotation.SnapTo(Player.ViewRotation, Player.ViewAngularVelocity);
		AccPivotDistance.SnapTo(800.0);
		AccPivotLocation.SnapTo(Player.ViewLocation + Player.ViewRotation.ForwardVector * AccPivotDistance.Value, Player.ActorVelocity);
			
		WorldLocation = Player.ViewLocation;
		WorldRotation = Player.ViewRotation;
	}

	void Update(float DeltaTime, float BlendDuration)
	{
		FTransform Transform = AttachMesh.GetSocketTransform(AttachSocketName);
		FRotator TargetRot = Transform.TransformRotation(TargetRelativeRotation);
		FVector TargetPivotLocation = Transform.TransformPosition(TargetRelativeLocation) + TargetRot.ForwardVector * TargetPivotDistance;

		if (BlendDuration == 0.0)
		{
			WorldLocation = Transform.TransformPosition(TargetRelativeLocation);
			WorldRotation = TargetRot;
			AccRotation.SnapTo(TargetRot);
			AccPivotDistance.SnapTo(TargetPivotDistance);
			AccPivotLocation.SnapTo(TargetPivotLocation);
			return;
		}

		AccRotation.AccelerateToWithStop(TargetRot, BlendDuration, DeltaTime, 1.0);

		AccPivotDistance.AccelerateToWithStop(TargetPivotDistance, BlendDuration, DeltaTime, 5.0);
		AccPivotLocation.AccelerateToWithStop(TargetPivotLocation, BlendDuration, DeltaTime, 10.0);	

		WorldLocation = AccPivotLocation.Value - AccRotation.Value.ForwardVector * AccPivotDistance.Value;
		WorldRotation = AccRotation.Value;	
	}
}
