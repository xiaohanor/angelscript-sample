UCLASS(Abstract)
class USketchbookGoatPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams MountedSlotAnimation;

	private AHazePlayerCharacter Player;
	ASketchbookGoat MountedGoat;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference MioGoatSoundDef;

	UPROPERTY(EditDefaultsOnly)
	FSoundDefReference ZoeGoatSoundDef;

	UPROPERTY()
	UForceFeedbackEffect MountForcefeedback;

	private FSoundDefReference GoatSoundDef;

	bool bWaitingDismount = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GoatSoundDef = Player.IsMio() ? MioGoatSoundDef : ZoeGoatSoundDef;
	}

	void MountGoat(ASketchbookGoat InGoat)
	{
		if(!ensure(!HasMountedGoat() && InGoat != nullptr))
			return;

		MountedGoat = InGoat;
		MountedGoat.OnMounted(Player);

		if(GoatSoundDef.SoundDef.IsValid())
			GoatSoundDef.SpawnSoundDefAttached(InGoat);

		Player.BlockCapabilitiesExcluding(CapabilityTags::Movement, CapabilityTags::MovementInput, this);
		Player.AttachToComponent(InGoat.PlayerAttachmentRoot);
		Player.PlayForceFeedback(MountForcefeedback,false,true,this,0.5);

	}

	void DismountGoat()
	{
		if(!ensure(HasMountedGoat()))
			return;

		MountedGoat.OnDismounted(Player);
		MountedGoat = nullptr;

		Player.DetachFromActor();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		Player.PlayForceFeedback(MountForcefeedback,false,true,this,0.5);

		if(GoatSoundDef.SoundDef.IsValid())
			Player.RemoveSoundDef(GoatSoundDef);
	}

	bool HasMountedGoat() const
	{
		return MountedGoat != nullptr;
	}
};

namespace Sketchbook::Goat
{
	UFUNCTION(BlueprintCallable)
	void DismountGoat(AHazePlayerCharacter Player)
	{
		auto GoatComp = USketchbookGoatPlayerComponent::Get(Player);
		if(GoatComp == nullptr)
			return;

		if(!GoatComp.HasMountedGoat())
			return;

		GoatComp.bWaitingDismount = true;
	}
}