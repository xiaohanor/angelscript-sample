#if EDITOR
class USummitDeathVolumeVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitDeathVolumeComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		USummitDeathVolumeComponent Comp = Cast<USummitDeathVolumeComponent>(Component);

		if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		SetRenderForeground(false);

		DrawWireSphere(Comp.WorldLocation, Comp.Size, FLinearColor::Red);
	}
}
#endif