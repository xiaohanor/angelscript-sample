UCLASS(Abstract)
class UIslandOverseerRollerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepTelegraphStart(FIslandOverseerRollerEventHandlerOnSweepTelegraphStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepTelegraphEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepAttackStart(FIslandOverseerRollerEventHandlerOnSweepAttackStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepAttackEnd() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepAttackInterrupted() {}	

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepDropLand() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepDrop() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSweepReverse() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDestroyed() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeployRoller(FIslandOverseerRollerEventHandlerOnDeployRollerData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnKnockback(FIslandOverseerRollerEventHandlerOnKnockbackData Data) {}
}

struct FIslandOverseerRollerEventHandlerOnKnockbackData
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	AHazePlayerCharacter KnockedPlayer;

	FIslandOverseerRollerEventHandlerOnKnockbackData(FVector _Location, AHazePlayerCharacter _KnockedPlayer)
	{
		Location = _Location;
		KnockedPlayer = _KnockedPlayer;
	}
}

struct FIslandOverseerRollerEventHandlerOnSweepAttackStartData
{
	USceneComponent RightFxContainer;
	USceneComponent LeftFxContainer;
	USceneComponent UpFxContainer;
	USceneComponent DownFxContainer;
}

struct FIslandOverseerRollerEventHandlerOnSweepTelegraphStartData
{
	UPROPERTY()
	FVector TelegraphLocation;
}

struct FIslandOverseerRollerEventHandlerOnDeployRollerData
{
	UPROPERTY()
	FVector AttachmentLocation;

	UPROPERTY()
	FName AttachmentSocket;

	FIslandOverseerRollerEventHandlerOnDeployRollerData(FVector InAttachmentLocation, FName InAttachmentSocket)
	{
		AttachmentLocation = InAttachmentLocation;
		AttachmentSocket = InAttachmentSocket;
	}
}