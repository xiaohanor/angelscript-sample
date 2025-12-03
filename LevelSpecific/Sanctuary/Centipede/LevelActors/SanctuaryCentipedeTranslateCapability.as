class USanctuaryCentipedeTranslateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASanctuaryCentipedeTranslateActor TranslateActor;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TranslateActor = Cast<ASanctuaryCentipedeTranslateActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TranslateActor.ControllingPlayer == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TranslateActor.ControllingPlayer == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = TranslateActor.ControllingPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		const FVector MoveInputXY = FVector(MoveInput.Y, MoveInput.X, 0);
		const FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
		const FRotator Rotation = FRotator::MakeFromX(Forward);
		const FVector Move = Rotation.RotateVector(MoveInputXY) * TranslateActor.Speed;

		TranslateActor.TranslateComp.ApplyForce(TranslateActor.TranslateComp.WorldLocation, Move);

		PrintToScreen("Hello" + Move);
	}
};