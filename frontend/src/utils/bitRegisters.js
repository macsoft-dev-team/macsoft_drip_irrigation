/**
 * Bit-packed register decoders / encoders.
 *
 * Device sends all registers as decimal integers over MQTT.
 * Registers 40001-40004 pack multiple boolean flags into one 16-bit word.
 *
 * Decode: decimal  →  individual bit flags (for display)
 * Encode: bit flags → decimal  (for command sending)
 */

// ─── MOD (40001) — 12 bits ───────────────────────────────────────────────────
// bit 0     : Auto Mode
// bit 1     : Manual Mode
// bits 2-6  : Pump 1-5 VFD Manual Mode
// bits 7-11 : Pump 1-5 DOL Manual Mode

export function decodeMOD(val = 0) {
    return {
        amo: !!(val & (1 << 0)),
        mmo: !!(val & (1 << 1)),
        p1v: !!(val & (1 << 2)),
        p2v: !!(val & (1 << 3)),
        p3v: !!(val & (1 << 4)),
        p4v: !!(val & (1 << 5)),
        p5v: !!(val & (1 << 6)),
        p1d: !!(val & (1 << 7)),
        p2d: !!(val & (1 << 8)),
        p3d: !!(val & (1 << 9)),
        p4d: !!(val & (1 << 10)),
        p5d: !!(val & (1 << 11)),
    };
}

/** Return a new MOD decimal value with a single bit toggled. */
export function encodeMODBit(currentVal = 0, bitIndex, bitValue) {
    if (bitValue) return currentVal | (1 << bitIndex);
    return currentVal & ~(1 << bitIndex);
}

/** MOD bit-index map for UI lookups */
export const MOD_BITS = {
    amo: 0,  mmo: 1,
    p1v: 2,  p2v: 3,  p3v: 4,  p4v: 5,  p5v: 6,
    p1d: 7,  p2d: 8,  p3d: 9,  p4d: 10, p5d: 11,
};

// ─── PRR (40002) — 5 bits ────────────────────────────────────────────────────
// bits 0-4 : Pump 1-5 Run Mins Reset

export function decodePRR(val = 0) {
    return {
        rm1: !!(val & (1 << 0)),
        rm2: !!(val & (1 << 1)),
        rm3: !!(val & (1 << 2)),
        rm4: !!(val & (1 << 3)),
        rm5: !!(val & (1 << 4)),
    };
}

export const PRR_BITS = { rm1: 0, rm2: 1, rm3: 2, rm4: 3, rm5: 4 };

// ─── PSM (40003) — 5 bits ────────────────────────────────────────────────────
// bits 0-4 : Pump 1-5 Service Mode ON/OFF

export function decodePSM(val = 0) {
    return {
        s1m: !!(val & (1 << 0)),
        s2m: !!(val & (1 << 1)),
        s3m: !!(val & (1 << 2)),
        s4m: !!(val & (1 << 3)),
        s5m: !!(val & (1 << 4)),
    };
}

export const PSM_BITS = { s1m: 0, s2m: 1, s3m: 2, s4m: 3, s5m: 4 };

// ─── PML (40004) — 4 bits ────────────────────────────────────────────────────
// bit 0 : Model 1+1 (2 pump)
// bit 1 : Model 2+1 (3 pump)
// bit 2 : Model 3+1 (4 pump)
// bit 3 : Model 4+1 (5 pump)

export function decodePML(val = 0) {
    return {
        m11: !!(val & (1 << 0)),
        m21: !!(val & (1 << 1)),
        m31: !!(val & (1 << 2)),
        m41: !!(val & (1 << 3)),
    };
}

/** Return active model index (0-3) or -1 if none set. */
export function activePumpModel(val = 0) {
    for (let i = 0; i < 4; i++) {
        if (val & (1 << i)) return i;
    }
    return -1;
}

export const PUMP_MODEL_LABELS = ['1+1 (2 Pump)', '2+1 (3 Pump)', '3+1 (4 Pump)', '4+1 (5 Pump)'];
export const PML_BITS = { m11: 0, m21: 1, m31: 2, m41: 3 };
