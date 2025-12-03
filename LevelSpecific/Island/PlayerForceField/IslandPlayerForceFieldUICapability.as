class UIslandPlayerForceFieldUICapability : UHazePlayerCapability
{
	UIslandForceFieldComponent ForceField;
	UIslandPlayerForceFieldUserComponent UserComp;

	const FLinearColor ShieldUIDestroyedColor = FLinearColor::Red;
	const FLinearColor ShieldUINormalColor = FLinearColor::Green;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceField = UIslandForceFieldComponent::Get(Player);
		UserComp = UIslandPlayerForceFieldUserComponent::Get(Player);

		UserComp.UIActor = SpawnActor(UserComp.UIActorClass);
		UserComp.UIActor.AddActorDisable(this);
		UserComp.UIActor.AttachToActor(Player, n"Spine2",
			EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		UserComp.UIActor.UIMesh.CreateDynamicMaterialInstance(0);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.UIActor.RemoveActorDisable(this);
		Outline::AddToPlayerOutlineActor(UserComp.UIActor, Player, this, EInstigatePriority::Normal);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.UIActor.AddActorDisable(this);
		Outline::ClearOutlineOnActor(UserComp.UIActor, Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FLinearColor Color = UserComp.bForceFieldIsDestroyed ? ShieldUIDestroyedColor : ShieldUINormalColor;
		UserComp.UIActor.UIMesh.SetScalarParameterValueOnMaterials(n"Alpha", ForceField.Integrity);
		UserComp.UIActor.UIMesh.SetVectorParameterValueOnMaterials(n"Color", FVector(Color.R, Color.G, Color.B));
	}
}