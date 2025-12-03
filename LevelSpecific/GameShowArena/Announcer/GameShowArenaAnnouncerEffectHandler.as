struct FGameShowArenaAnnouncerVOParams
{
	FGameShowArenaAnnouncerVOParams(AGameShowArenaAnnouncer Announcer)
	{
		TalkingAnnouncer = Announcer;
	}
	UPROPERTY()
	AGameShowArenaAnnouncer TalkingAnnouncer;
}

UCLASS(Abstract)
class UGameShowArenaAnnouncerEffectHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationIntro(FGameShowArenaAnnouncerVOParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationTutorial(FGameShowArenaAnnouncerVOParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationBombTossA(FGameShowArenaAnnouncerVOParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationBombTossB(FGameShowArenaAnnouncerVOParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationBombTossC(FGameShowArenaAnnouncerVOParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationBombTossD(FGameShowArenaAnnouncerVOParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationBombTossE(FGameShowArenaAnnouncerVOParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void PresentationBombTossEnding(FGameShowArenaAnnouncerVOParams Params){}

	/** Triggers when the player not holding a bomb opens the hatch. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchOpenStart(FGameShowArenaHatchHolderParams Params) {}
	/** Triggers when the player not holding a bomb closes the hatch without a bomb having been thrown in. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchCloseStart(FGameShowArenaHatchHolderParams Params) {}

	/** Triggers when the player with bomb starts interacting. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchBombPlayerReadyStart(FGameShowArenaHatchBombHolderParams Params) {}
	/** Triggers when the player with bomb stops interacting without dunking it. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHatchBombPlayerReadyStopped(FGameShowArenaHatchBombHolderParams Params) {}

	/** Triggers when interaction is done and one player throws in bomb as the other closes the hatch.  */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBombDisposalStarted(FGameShowArenaHatchBothPlayerParams Params) {}
	/** Triggers when bomb has been thrown in and hatch has been closed. */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBombDisposed(FGameShowArenaHatchBothPlayerParams Params) {}
};