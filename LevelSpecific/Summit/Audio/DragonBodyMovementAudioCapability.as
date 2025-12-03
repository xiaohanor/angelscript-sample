class UDragonBodyMovementAudioCapability : UHazeCapability
{
	UMeshComponent DragonMesh;
	UDragonMovementAudioComponent DragonMoveComp;

	FVector LastSocketLocation;
	FVector LastDragonLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{				
		UPlayerTeenDragonComponent DragonComp = UPlayerTeenDragonComponent::Get(Owner);		
		DragonMesh = DragonComp.DragonMesh;		

		ATeenDragon Dragon = Cast<ATeenDragon>(DragonMesh.GetOwner());
		DragonMoveComp = UDragonMovementAudioComponent::Get(Dragon);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DragonMoveComp.MovementSettings == nullptr)
			return false;

		if(DragonMoveComp.IsMovementBlocked(EMovementAudioFlags::Armswing))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(DragonMoveComp.IsMovementBlocked(EMovementAudioFlags::Armswing))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector SocketLocation = DragonMesh.GetSocketLocation(MovementAudio::Dragons::SpineSocketName);
		const FVector DragonLocation = DragonMesh.GetCenterOfMass();

		const FVector DragonVelo = DragonLocation - LastDragonLocation;
		FVector SocketVelo = (SocketLocation - LastSocketLocation) - DragonVelo;

		const float SocketRelativeVeloSpeed = (SocketVelo.Size() / DeltaTime) / DragonMoveComp.MovementSettings.BodyMovementVelocityRange;
		DragonMoveComp.SetBodyMovementSocketRelativeSpeed(SocketRelativeVeloSpeed);

		const float MovementSpeed = (DragonVelo.Size() / DeltaTime) / DragonMoveComp.MovementSettings.MovementVelocityRange;		
		DragonMoveComp.SetBodyMovementVelocitySpeed(MovementSpeed);

		LastSocketLocation = SocketLocation;
		LastDragonLocation = DragonLocation;
	}

}