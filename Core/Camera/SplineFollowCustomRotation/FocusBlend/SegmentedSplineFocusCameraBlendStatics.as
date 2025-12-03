namespace FocusCameraBlend
{
	void Editor_CreateSplineKey(AActor Actor)
	{
		UFocusCameraBlendSplineKey SplineKey = UFocusCameraBlendSplineKey::Create(Actor);
		Editor::TriggerPostEditMove(Actor);
		// Editor::SelectComponent(SplineKey, true);
	}
}