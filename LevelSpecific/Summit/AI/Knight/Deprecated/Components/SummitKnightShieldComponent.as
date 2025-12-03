event void SummitKnightShieldBlockSignature();
event void SummitKnightAcidDodgeCompletedSignature();

class USummitKnightShieldComponent : UStaticMeshComponent
{
	SummitKnightShieldBlockSignature OnRollBlock;
	bool bEnabled = true;
	bool bReformed;
	SummitKnightAcidDodgeCompletedSignature OnAcidDodgeCompleted;
}